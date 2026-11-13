import { Router, Request, Response, NextFunction } from 'express';
import { authenticate } from '../../common/middleware/auth';
import { RecurringExpenseModel } from './recurring.model';
import { sendSuccess } from '../../common/response';
import { NotFoundError, AppError } from '../../common/errors';

const router = Router();
router.use(authenticate);

router.get('/', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const userId = req.user!.userId;
    let subscriptions = await RecurringExpenseModel.find({ userId }).sort({ nextBillingDate: 1 });

    if (subscriptions.length === 0) {
      subscriptions = await RecurringExpenseModel.create([
        {
          userId,
          name: 'Netflix 4K Ultra',
          amountPaise: 64900, // ₹649.00
          category: 'Entertainment',
          frequency: 'monthly',
          nextBillingDate: new Date('2026-11-20'),
          color: '#E50914',
          icon: 'movie',
        },
        {
          userId,
          name: 'Spotify Premium Duo',
          amountPaise: 14900, // ₹149.00
          category: 'Entertainment',
          frequency: 'monthly',
          nextBillingDate: new Date('2026-11-22'),
          color: '#1DB954',
          icon: 'music_note',
        },
        {
          userId,
          name: 'Apple iCloud+ 2TB',
          amountPaise: 74900, // ₹749.00
          category: 'Cloud Services',
          frequency: 'monthly',
          nextBillingDate: new Date('2026-11-28'),
          color: '#4388FF',
          icon: 'cloud',
        },
        {
          userId,
          name: 'Anytime Fitness Gym',
          amountPaise: 250000, // ₹2,500.00
          category: 'Health & Fitness',
          frequency: 'monthly',
          nextBillingDate: new Date('2026-12-01'),
          color: '#FFA94D',
          icon: 'fitness_center',
        },
      ]);
    }

    const totalMonthlyCommitmentPaise = subscriptions.reduce((acc, s) => acc + s.amountPaise, 0);

    sendSuccess(res, {
      subscriptions,
      totalMonthlyCommitmentPaise,
    }, 'Recurring expenses retrieved');
  } catch (error) {
    next(error);
  }
});

router.post('/', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const userId = req.user!.userId;
    const { name, amountPaise, category, frequency, nextBillingDate, color, icon } = req.body;

    if (!name || !amountPaise || !nextBillingDate) {
      throw new AppError('Name, amount, and nextBillingDate are required', 400);
    }

    const subscription = await RecurringExpenseModel.create({
      userId,
      name,
      amountPaise,
      category: category || 'Subscriptions',
      frequency: frequency || 'monthly',
      nextBillingDate: new Date(nextBillingDate),
      color: color || '#8B5CF6',
      icon: icon || 'subscriptions',
    });

    sendSuccess(res, { subscription }, 'Subscription added successfully', 201);
  } catch (error) {
    next(error);
  }
});

export const recurringRouter = router;
