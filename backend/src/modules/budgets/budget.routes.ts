import { Router, Request, Response, NextFunction } from 'express';
import { authenticate } from '../../common/middleware/auth';
import { BudgetModel } from './budget.model';
import { sendSuccess } from '../../common/response';
import { NotFoundError } from '../../common/errors';

const router = Router();
router.use(authenticate);

// Get budgets for a given month (e.g., "2026-11")
router.get('/', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const userId = req.user!.userId;
    const now = new Date();
    const currentMonthYear = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`;
    const monthYear = (req.query.monthYear as string) || currentMonthYear;

    let budgets = await BudgetModel.find({ userId, monthYear }).populate('categoryId');

    if (budgets.length === 0) {
      // Seed initial dummy budgets for user display
      const { CategoryModel } = require('../categories/category.model');
      const categories = await CategoryModel.find({ isSystem: true, type: 'expense' }).limit(3);
      if (categories.length > 0) {
        budgets = await BudgetModel.create([
          {
            userId,
            categoryId: categories[0]._id,
            limitPaise: 1500000, // ₹15,000
            spentPaise: 980000,  // ₹9,800
            monthYear,
            alertThresholdPercentage: 80,
          },
          {
            userId,
            categoryId: categories[1]._id,
            limitPaise: 2500000, // ₹25,000
            spentPaise: 1840000, // ₹18,400
            monthYear,
            alertThresholdPercentage: 80,
          },
        ]);
        budgets = await BudgetModel.find({ userId, monthYear }).populate('categoryId');
      }
    }

    const totalLimitPaise = budgets.reduce((acc, b) => acc + b.limitPaise, 0);
    const totalSpentPaise = budgets.reduce((acc, b) => acc + b.spentPaise, 0);

    sendSuccess(res, {
      budgets,
      summary: {
        totalLimitPaise,
        totalSpentPaise,
        remainingPaise: Math.max(0, totalLimitPaise - totalSpentPaise),
        percentageUsed: totalLimitPaise > 0 ? Math.round((totalSpentPaise / totalLimitPaise) * 100) : 0,
      },
    }, 'Budgets retrieved');
  } catch (error) {
    next(error);
  }
});

// Set or update a category budget
router.post('/', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const userId = req.user!.userId;
    const { categoryId, limitPaise, monthYear, alertThresholdPercentage } = req.body;

    const budget = await BudgetModel.findOneAndUpdate(
      { userId, categoryId, monthYear },
      {
        $set: {
          limitPaise,
          alertThresholdPercentage: alertThresholdPercentage || 80,
        },
      },
      { upsert: true, new: true }
    ).populate('categoryId');

    sendSuccess(res, { budget }, 'Budget saved successfully');
  } catch (error) {
    next(error);
  }
});

export const budgetRouter = router;
