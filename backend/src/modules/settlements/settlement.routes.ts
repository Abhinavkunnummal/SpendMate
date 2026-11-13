import { Router, Request, Response, NextFunction } from 'express';
import { authenticate } from '../../common/middleware/auth';
import { TripModel } from '../trips/trip.model';
import { TripExpenseModel } from '../trip_expenses/trip-expense.model';
import { SettlementModel } from './settlement.model';
import { DebtMinimizer, MemberNetBalance } from './debt-minimizer';
import { sendSuccess } from '../../common/response';
import { NotFoundError, AppError } from '../../common/errors';

const router = Router();
router.use(authenticate);

// Get balances and optimal settlements for a trip
router.get('/trip/:tripId', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const tripId = req.params.tripId;
    const trip = await TripModel.findById(tripId);
    if (!trip) throw new NotFoundError('Trip not found');

    const expenses = await TripExpenseModel.find({ tripId });
    const existingSettlements = await SettlementModel.find({ tripId });

    // Map member balances
    const balanceMap = new Map<string, { name: string; paid: number; owed: number }>();

    trip.members.forEach((m) => {
      const id = m._id ? m._id.toString() : m.name;
      balanceMap.set(id, { name: m.name, paid: 0, owed: 0 });
    });

    // Accumulate contributions and shared shares
    for (const exp of expenses) {
      // Contributed (paid)
      for (const p of exp.paidBy) {
        if (!balanceMap.has(p.memberId)) {
          balanceMap.set(p.memberId, { name: p.name, paid: 0, owed: 0 });
        }
        balanceMap.get(p.memberId)!.paid += p.amountPaise;
      }

      // Shared (owed)
      for (const s of exp.splits) {
        if (!balanceMap.has(s.memberId)) {
          balanceMap.set(s.memberId, { name: s.name, paid: 0, owed: 0 });
        }
        balanceMap.get(s.memberId)!.owed += s.sharePaise;
      }
    }

    // Adjust for already completed settlements
    for (const s of existingSettlements) {
      if (s.status === 'completed' || s.status === 'verified') {
        if (balanceMap.has(s.fromMemberId)) {
          balanceMap.get(s.fromMemberId)!.paid += s.amountPaise; // payer's debt is cleared
        }
        if (balanceMap.has(s.toMemberId)) {
          balanceMap.get(s.toMemberId)!.owed += s.amountPaise; // receiver's credit is satisfied
        }
      }
    }

    // Build member net balances array
    const memberBalances: MemberNetBalance[] = [];
    balanceMap.forEach((val, id) => {
      const net = val.paid - val.owed;
      memberBalances.push({
        memberId: id,
        name: val.name,
        netBalancePaise: net,
      });
    });

    // Compute optimal minimal settlement transactions
    const suggestedPayments = DebtMinimizer.calculateSettlements(memberBalances);

    sendSuccess(res, {
      memberBalances,
      suggestedPayments,
      existingSettlements,
    }, 'Balances and settlements calculated');
  } catch (error) {
    next(error);
  }
});

// Record a settlement payment
router.post('/', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { tripId, fromMemberId, fromName, toMemberId, toName, amountPaise, paymentMethod, transactionReference, proofImageUrl } = req.body;

    if (!tripId || !fromMemberId || !toMemberId || !amountPaise) {
      throw new AppError('TripId, fromMember, toMember, and amountPaise are required', 400);
    }

    const settlement = await SettlementModel.create({
      tripId,
      fromMemberId,
      fromName: fromName || 'Payer',
      toMemberId,
      toName: toName || 'Receiver',
      amountPaise,
      paymentMethod: paymentMethod || 'UPI',
      transactionReference,
      proofImageUrl,
      status: 'completed',
      settledAt: new Date(),
    });

    sendSuccess(res, { settlement }, 'Settlement recorded successfully', 201);
  } catch (error) {
    next(error);
  }
});

export const settlementRouter = router;
