import { Router, Request, Response, NextFunction } from 'express';
import { authenticate } from '../../common/middleware/auth';
import { SavingsGoalModel } from './savings.model';
import { sendSuccess } from '../../common/response';
import { NotFoundError, AppError } from '../../common/errors';

const router = Router();
router.use(authenticate);

// Get all savings goals
router.get('/', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const userId = req.user!.userId;
    let goals = await SavingsGoalModel.find({ userId }).sort({ createdAt: -1 });

    if (goals.length === 0) {
      goals = await SavingsGoalModel.create([
        {
          userId,
          name: 'Japan Autumn Trip 2027',
          targetAmountPaise: 25000000, // ₹2,50,000.00
          currentAmountPaise: 11000000, // ₹1,10,000.00
          targetDate: new Date('2027-10-15'),
          icon: 'flight',
          color: '#4388FF',
          status: 'in_progress',
        },
        {
          userId,
          name: 'Emergency Fund',
          targetAmountPaise: 30000000, // ₹3,00,000.00
          currentAmountPaise: 21500000, // ₹2,15,000.00
          icon: 'security',
          color: '#16A878',
          status: 'in_progress',
        },
        {
          userId,
          name: 'MacBook Pro M3 Max',
          targetAmountPaise: 20000000, // ₹2,00,000.00
          currentAmountPaise: 18000000, // ₹1,80,000.00
          icon: 'laptop_mac',
          color: '#8B5CF6',
          status: 'in_progress',
        },
      ]);
    }

    const totalSavedPaise = goals.reduce((acc, g) => acc + g.currentAmountPaise, 0);
    const totalTargetPaise = goals.reduce((acc, g) => acc + g.targetAmountPaise, 0);

    sendSuccess(res, {
      goals,
      summary: {
        totalSavedPaise,
        totalTargetPaise,
        overallPercentage: totalTargetPaise > 0 ? Math.round((totalSavedPaise / totalTargetPaise) * 100) : 0,
      },
    }, 'Savings goals retrieved');
  } catch (error) {
    next(error);
  }
});

// Create savings goal
router.post('/', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const userId = req.user!.userId;
    const { name, targetAmountPaise, currentAmountPaise, targetDate, icon, color } = req.body;

    if (!name || !targetAmountPaise) {
      throw new AppError('Name and target amount are required', 400);
    }

    const goal = await SavingsGoalModel.create({
      userId,
      name,
      targetAmountPaise,
      currentAmountPaise: currentAmountPaise || 0,
      targetDate: targetDate ? new Date(targetDate) : undefined,
      icon: icon || 'savings',
      color: color || '#16A878',
    });

    sendSuccess(res, { goal }, 'Savings goal created', 201);
  } catch (error) {
    next(error);
  }
});

// Deposit or withdraw from savings goal
router.post('/:id/contribute', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const userId = req.user!.userId;
    const { amountPaise, isWithdrawal } = req.body;

    if (!amountPaise || amountPaise <= 0) {
      throw new AppError('Valid amount in paise is required', 400);
    }

    const goal = await SavingsGoalModel.findOne({ _id: req.params.id, userId });
    if (!goal) throw new NotFoundError('Savings goal not found');

    const change = isWithdrawal ? -amountPaise : amountPaise;
    goal.currentAmountPaise = Math.max(0, goal.currentAmountPaise + change);
    if (goal.currentAmountPaise >= goal.targetAmountPaise) {
      goal.status = 'completed';
    } else {
      goal.status = 'in_progress';
    }

    await goal.save();
    sendSuccess(res, { goal }, isWithdrawal ? 'Withdrawn from goal' : 'Added to savings goal');
  } catch (error) {
    next(error);
  }
});

export const savingsRouter = router;
