import { Router, Request, Response, NextFunction } from 'express';
import { authenticate } from '../../common/middleware/auth';
import { CategoryModel } from './category.model';
import { sendSuccess } from '../../common/response';

const router = Router();
router.use(authenticate);

const DEFAULT_CATEGORIES = [
  // Expenses
  { name: 'Food & Dining', type: 'expense', icon: 'restaurant', color: '#FF6B6B', isSystem: true },
  { name: 'Travel & Trips', type: 'expense', icon: 'flight_takeoff', color: '#4388FF', isSystem: true },
  { name: 'Groceries', type: 'expense', icon: 'shopping_basket', color: '#16A878', isSystem: true },
  { name: 'Shopping', type: 'expense', icon: 'shopping_bag', color: '#FFA94D', isSystem: true },
  { name: 'Bills & Utilities', type: 'expense', icon: 'receipt_long', color: '#8B5CF6', isSystem: true },
  { name: 'Entertainment', type: 'expense', icon: 'movie', color: '#EC4899', isSystem: true },
  { name: 'Health & Medical', type: 'expense', icon: 'medical_services', color: '#10B981', isSystem: true },
  { name: 'Transport & Fuel', type: 'expense', icon: 'local_gas_station', color: '#F59E0B', isSystem: true },
  // Income
  { name: 'Salary', type: 'income', icon: 'payments', color: '#16A878', isSystem: true },
  { name: 'Freelance & Bonus', type: 'income', icon: 'laptop_chromebook', color: '#4388FF', isSystem: true },
  { name: 'Investments', type: 'income', icon: 'trending_up', color: '#8B5CF6', isSystem: true },
];

router.get('/', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const userId = req.user!.userId;
    let categories = await CategoryModel.find({
      $or: [{ userId }, { isSystem: true }],
    }).sort({ type: 1, name: 1 });

    if (categories.length === 0) {
      categories = await CategoryModel.create(DEFAULT_CATEGORIES);
    }

    sendSuccess(res, { categories }, 'Categories retrieved successfully');
  } catch (error) {
    next(error);
  }
});

router.post('/', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const userId = req.user!.userId;
    const { name, type, icon, color } = req.body;

    const category = await CategoryModel.create({
      userId,
      name,
      type: type || 'expense',
      icon: icon || 'category',
      color: color || '#16A878',
      isSystem: false,
    });

    sendSuccess(res, { category }, 'Category created successfully', 201);
  } catch (error) {
    next(error);
  }
});

export const categoryRouter = router;
