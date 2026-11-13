import { Router, Request, Response, NextFunction } from 'express';
import { authenticate } from '../../common/middleware/auth';
import { TransactionModel } from '../transactions/transaction.model';
import { TripModel } from '../trips/trip.model';
import { TripExpenseModel } from '../trip_expenses/trip-expense.model';
import { SettlementModel } from '../settlements/settlement.model';
import { sendSuccess } from '../../common/response';

const router = Router();
router.use(authenticate);

// Delta Sync: returns records modified since `lastSyncTimestamp`
router.post('/pull', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const userId = req.user!.userId;
    const { lastSyncTimestamp } = req.body;

    const sinceDate = lastSyncTimestamp ? new Date(lastSyncTimestamp) : new Date(0);

    const [transactions, trips, expenses, settlements] = await Promise.all([
      TransactionModel.find({ userId, updatedAt: { $gt: sinceDate } }),
      TripModel.find({
        $or: [{ creatorId: userId }, { 'members.userId': userId }],
        updatedAt: { $gt: sinceDate },
      }),
      TripExpenseModel.find({ updatedAt: { $gt: sinceDate } }),
      SettlementModel.find({ updatedAt: { $gt: sinceDate } }),
    ]);

    sendSuccess(res, {
      delta: {
        transactions,
        trips,
        expenses,
        settlements,
      },
      currentTimestamp: new Date().toISOString(),
    }, 'Delta sync retrieved');
  } catch (error) {
    next(error);
  }
});

export const syncRouter = router;
