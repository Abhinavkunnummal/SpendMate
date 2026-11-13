import { Router, Request, Response, NextFunction } from 'express';
import { authenticate } from '../../common/middleware/auth';
import { TransactionModel } from './transaction.model';
import { WalletModel } from '../wallets/wallet.model';
import { sendSuccess } from '../../common/response';
import { NotFoundError, AppError } from '../../common/errors';
import mongoose from 'mongoose';

const router = Router();
router.use(authenticate);

// Get transactions list with filters
router.get('/', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const userId = req.user!.userId;
    const { type, walletId, categoryId, search, limit = '20', page = '1' } = req.query;

    const query: any = { userId };

    if (type && ['expense', 'income', 'transfer'].includes(type as string)) {
      query.type = type;
    }
    if (walletId) query.walletId = walletId;
    if (categoryId) query.categoryId = categoryId;
    if (search) {
      query.description = { $regex: search as string, $options: 'i' };
    }

    const pageSize = parseInt(limit as string, 10);
    const currentPage = parseInt(page as string, 10);
    const skip = (currentPage - 1) * pageSize;

    const [transactions, totalCount] = await Promise.all([
      TransactionModel.find(query)
        .populate('walletId', 'name color icon')
        .populate('categoryId', 'name icon color')
        .sort({ date: -1 })
        .skip(skip)
        .limit(pageSize),
      TransactionModel.countDocuments(query),
    ]);

    sendSuccess(
      res,
      { transactions },
      'Transactions retrieved successfully',
      200,
      {
        totalCount,
        currentPage,
        totalPages: Math.ceil(totalCount / pageSize),
        hasMore: skip + transactions.length < totalCount,
      }
    );
  } catch (error) {
    next(error);
  }
});

// Get transaction details
router.get('/:id', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const userId = req.user!.userId;
    const transaction = await TransactionModel.findOne({ _id: req.params.id, userId })
      .populate('walletId')
      .populate('categoryId');

    if (!transaction) throw new NotFoundError('Transaction not found');

    sendSuccess(res, { transaction }, 'Transaction details');
  } catch (error) {
    next(error);
  }
});

// Create transaction & atomically adjust wallet balance
router.post('/', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const userId = req.user!.userId;
    const { walletId, categoryId, amountPaise, type, description, notes, date, receiptUrl, tags } = req.body;

    if (!walletId || !categoryId || !amountPaise || !type || !description) {
      throw new AppError('Missing required transaction fields', 400);
    }

    const wallet = await WalletModel.findOne({ _id: walletId, userId });
    if (!wallet) throw new NotFoundError('Wallet not found');

    const transaction = await TransactionModel.create({
      userId,
      walletId,
      categoryId,
      amountPaise,
      type,
      description,
      notes,
      date: date ? new Date(date) : new Date(),
      receiptUrl,
      tags: tags || [],
    });

    // Update wallet balance in paise
    const balanceChange = type === 'income' ? amountPaise : -amountPaise;
    wallet.balancePaise += balanceChange;
    await wallet.save();

    const populated = await TransactionModel.findById(transaction._id)
      .populate('walletId', 'name color icon')
      .populate('categoryId', 'name icon color');

    sendSuccess(res, { transaction: populated, updatedWalletBalance: wallet.balancePaise }, 'Transaction created', 201);
  } catch (error) {
    next(error);
  }
});

// Delete transaction & revert balance
router.delete('/:id', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const userId = req.user!.userId;
    const transaction = await TransactionModel.findOneAndDelete({ _id: req.params.id, userId });
    if (!transaction) throw new NotFoundError('Transaction not found');

    // Revert wallet balance
    const revertChange = transaction.type === 'income' ? -transaction.amountPaise : transaction.amountPaise;
    await WalletModel.updateOne({ _id: transaction.walletId }, { $inc: { balancePaise: revertChange } });

    sendSuccess(res, null, 'Transaction deleted successfully');
  } catch (error) {
    next(error);
  }
});

export const transactionRouter = router;
