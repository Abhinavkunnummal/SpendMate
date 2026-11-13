import { Router, Request, Response, NextFunction } from 'express';
import { authenticate } from '../../common/middleware/auth';
import { WalletModel } from './wallet.model';
import { sendSuccess } from '../../common/response';
import { NotFoundError, AppError } from '../../common/errors';
import mongoose from 'mongoose';

const router = Router();
router.use(authenticate);

// Get all wallets for user
router.get('/', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const userId = req.user!.userId;
    let wallets = await WalletModel.find({ userId }).sort({ isDefault: -1, createdAt: 1 });

    // Seed default wallets if user has none
    if (wallets.length === 0) {
      wallets = await WalletModel.create([
        {
          userId,
          name: 'HDFC Salary Account',
          type: 'bank',
          balancePaise: 8540000, // ₹85,400.00
          accountNumberLast4: '4821',
          color: '#16A878',
          icon: 'account_balance',
          isDefault: true,
        },
        {
          userId,
          name: 'ICICI Credit Card',
          type: 'credit_card',
          balancePaise: -1250000, // -₹12,500.00
          accountNumberLast4: '9012',
          color: '#FF6B6B',
          icon: 'credit_card',
          isDefault: false,
        },
        {
          userId,
          name: 'Cash In Hand',
          type: 'cash',
          balancePaise: 450000, // ₹4,500.00
          color: '#FFA94D',
          icon: 'payments',
          isDefault: false,
        },
        {
          userId,
          name: 'Google Pay UPI',
          type: 'upi',
          balancePaise: 1520000, // ₹15,200.00
          color: '#4388FF',
          icon: 'qr_code_2',
          isDefault: false,
        },
      ]);
    }

    const totalLiquidityPaise = wallets.reduce((acc, w) => acc + w.balancePaise, 0);

    sendSuccess(
      res,
      { wallets, totalLiquidityPaise },
      'Wallets retrieved successfully'
    );
  } catch (error) {
    next(error);
  }
});

// Create wallet
router.post('/', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const userId = req.user!.userId;
    const { name, type, balancePaise, accountNumberLast4, color, icon, isDefault } = req.body;

    if (!name) {
      throw new AppError('Wallet name is required', 400);
    }

    if (isDefault) {
      await WalletModel.updateMany({ userId }, { $set: { isDefault: false } });
    }

    const wallet = await WalletModel.create({
      userId,
      name,
      type: type || 'bank',
      balancePaise: balancePaise || 0,
      accountNumberLast4,
      color: color || '#16A878',
      icon: icon || 'account_balance_wallet',
      isDefault: isDefault ?? false,
    });

    sendSuccess(res, { wallet }, 'Wallet created successfully', 201);
  } catch (error) {
    next(error);
  }
});

// Update wallet
router.put('/:id', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const userId = req.user!.userId;
    const walletId = req.params.id;

    const wallet = await WalletModel.findOneAndUpdate(
      { _id: walletId, userId },
      { $set: req.body },
      { new: true }
    );

    if (!wallet) throw new NotFoundError('Wallet not found');

    sendSuccess(res, { wallet }, 'Wallet updated successfully');
  } catch (error) {
    next(error);
  }
});

// Delete wallet
router.delete('/:id', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const userId = req.user!.userId;
    const walletId = req.params.id;

    const wallet = await WalletModel.findOneAndDelete({ _id: walletId, userId });
    if (!wallet) throw new NotFoundError('Wallet not found');

    sendSuccess(res, null, 'Wallet deleted successfully');
  } catch (error) {
    next(error);
  }
});

export const walletRouter = router;
