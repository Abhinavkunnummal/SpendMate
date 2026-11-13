import { Router, Request, Response, NextFunction } from 'express';
import { authenticate } from '../../common/middleware/auth';
import { TripExpenseModel, IContributor, ISplitShare } from './trip-expense.model';
import { TripModel } from '../trips/trip.model';
import { DebtMinimizer } from '../settlements/debt-minimizer';
import { sendSuccess } from '../../common/response';
import { NotFoundError, AppError } from '../../common/errors';
import mongoose from 'mongoose';

const router = Router();
router.use(authenticate);

// Get all group expenses for a trip
router.get('/trip/:tripId', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const tripId = req.params.tripId;
    const expenses = await TripExpenseModel.find({ tripId }).sort({ date: -1 });

    const totalExpensePaise = expenses.reduce((acc, e) => acc + e.amountPaise, 0);

    sendSuccess(res, { expenses, totalExpensePaise }, 'Trip expenses retrieved');
  } catch (error) {
    next(error);
  }
});

// Add a multi-payer group expense
router.post('/', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const userId = req.user!.userId;
    const {
      tripId,
      description,
      amountPaise,
      category,
      paidBy, // Array<{ memberId, name, amountPaise }>
      splitType, // 'equal' | 'exact' | 'percentage'
      participantIds, // string[]
      customSplits, // optional Array<{ memberId, name, sharePaise, percentage }>
      receiptUrl,
      notes,
    } = req.body;

    if (!tripId || !description || !amountPaise || !paidBy || paidBy.length === 0) {
      throw new AppError('TripId, description, amountPaise, and paidBy are required', 400);
    }

    const trip = await TripModel.findById(tripId);
    if (!trip) throw new NotFoundError('Trip not found');

    // 1. Validate Multi-Payer Contributions
    const totalContributed = (paidBy as IContributor[]).reduce((sum, c) => sum + c.amountPaise, 0);
    if (totalContributed !== amountPaise) {
      throw new AppError(
        `Total contributed (${totalContributed} paise) does not match expense amount (${amountPaise} paise)`,
        400
      );
    }

    // 2. Calculate Splits
    let splits: ISplitShare[] = [];

    if (splitType === 'equal' || !splitType) {
      const pIds = participantIds || trip.members.map((m) => (m._id ? m._id.toString() : m.name));
      const shareMap = DebtMinimizer.splitEqually(amountPaise, pIds);

      splits = pIds.map((id: string) => {
        const member = trip.members.find((m) => (m._id ? m._id.toString() : m.name) === id);
        return {
          memberId: id,
          name: member ? member.name : id,
          sharePaise: shareMap.get(id) || 0,
        };
      });
    } else if (splitType === 'exact') {
      if (!customSplits || customSplits.length === 0) {
        throw new AppError('customSplits required for exact split', 400);
      }
      const sumExact = customSplits.reduce((acc: number, s: any) => acc + s.sharePaise, 0);
      if (sumExact !== amountPaise) {
        throw new AppError(`Sum of custom splits (${sumExact}) must equal total (${amountPaise})`, 400);
      }
      splits = customSplits;
    } else if (splitType === 'percentage') {
      if (!customSplits || customSplits.length === 0) {
        throw new AppError('customSplits required for percentage split', 400);
      }
      const sumPercent = customSplits.reduce((acc: number, s: any) => acc + s.percentage, 0);
      if (Math.round(sumPercent) !== 100) {
        throw new AppError(`Total percentage must equal 100% (got ${sumPercent}%)`, 400);
      }
      splits = customSplits.map((s: any) => ({
        memberId: s.memberId,
        name: s.name,
        percentage: s.percentage,
        sharePaise: Math.round((amountPaise * s.percentage) / 100),
      }));
    }

    const expense = await TripExpenseModel.create({
      tripId,
      createdBy: new mongoose.Types.ObjectId(userId),
      description,
      amountPaise,
      category: category || 'General',
      paidBy,
      splitType: splitType || 'equal',
      splits,
      receiptUrl,
      notes,
    });

    // Update trip total spent
    trip.totalSpentPaise += amountPaise;
    await trip.save();

    sendSuccess(res, { expense }, 'Group expense recorded successfully', 201);
  } catch (error) {
    next(error);
  }
});

export const tripExpenseRouter = router;
