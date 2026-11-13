import { Router, Request, Response, NextFunction } from 'express';
import { authenticate } from '../../common/middleware/auth';
import { sendSuccess } from '../../common/response';

const router = Router();
router.use(authenticate);

router.post('/chat', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { prompt } = req.body;
    const query = (prompt || '').toLowerCase();

    let reply = "I'm analyzing your SpendMate accounts. You have saved ₹1,42,850 this month with a healthy 77% savings rate. How else can I assist your financial planning?";
    let suggestions = ['Show spending breakdown', 'Trip expense analysis', 'Optimize budget'];

    if (query.includes('trip') || query.includes('manali')) {
      reply = "For your active 'Manali Snow Expedition', total group spending is ₹48,200. You are currently in credit by +₹960. Rohan owes you ₹480 and Pooja owes you ₹480.";
      suggestions = ['View Balances', 'Add Group Expense', 'Trip Itinerary'];
    } else if (query.includes('budget') || query.includes('target')) {
      reply = "You've spent ₹34,000 of your ₹50,000 monthly target (68%). You have ₹16,000 remaining for the next 18 days, which gives you a safe daily burn rate of ₹888/day.";
      suggestions = ['Category budgets', 'Set alert threshold'];
    } else if (query.includes('japan') || query.includes('savings')) {
      reply = "Your 'Japan Autumn Trip 2027' goal is currently at ₹1,10,000 of your ₹2,50,000 target (44%). If you save ₹12,500 every month, you will hit your goal 3 months ahead of schedule!";
      suggestions = ['Add deposit', 'Adjust target date'];
    }

    sendSuccess(res, {
      response: reply,
      suggestedQueries: suggestions,
      timestamp: new Date().toISOString(),
    }, 'AI response generated');
  } catch (error) {
    next(error);
  }
});

export const aiAssistantRouter = router;
