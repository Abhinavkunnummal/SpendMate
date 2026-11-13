import { Router, Request, Response, NextFunction } from 'express';
import { authenticate } from '../../common/middleware/auth';
import { NotificationModel } from './notification.model';
import { sendSuccess } from '../../common/response';

const router = Router();
router.use(authenticate);

router.get('/', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const userId = req.user!.userId;
    let notifications = await NotificationModel.find({ userId }).sort({ createdAt: -1 });

    if (notifications.length === 0) {
      notifications = await NotificationModel.create([
        {
          userId,
          title: 'Settlement Payment Pending',
          message: 'Rohan owes you ₹480 for Sightseeing Shuttle Tickets in Manali.',
          type: 'settlement',
          isRead: false,
          actionUrl: '/settlements/settle-101',
        },
        {
          userId,
          title: 'Group Expense Added',
          message: 'Aarav recorded Sightseeing & Shuttle Tickets (₹560) in Manali Snow Expedition.',
          type: 'trip',
          isRead: false,
          actionUrl: '/trips/trip-manali-101',
        },
        {
          userId,
          title: 'Shopping Budget Alert',
          message: 'You have used 81% of your Shopping & Apparel budget for November.',
          type: 'budget_alert',
          isRead: true,
          actionUrl: '/budgets',
        },
        {
          userId,
          title: 'Upcoming Subscription Renewal',
          message: 'Netflix 4K Ultra (₹649) is scheduled for renewal in 3 days.',
          type: 'recurring_due',
          isRead: true,
          actionUrl: '/recurring-expenses',
        },
      ]);
    }

    const unreadCount = notifications.filter((n) => !n.isRead).length;

    sendSuccess(res, { notifications, unreadCount }, 'Notifications retrieved');
  } catch (error) {
    next(error);
  }
});

router.patch('/:id/read', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const userId = req.user!.userId;
    await NotificationModel.updateOne({ _id: req.params.id, userId }, { $set: { isRead: true } });
    sendSuccess(res, null, 'Notification marked as read');
  } catch (error) {
    next(error);
  }
});

export const notificationRouter = router;
