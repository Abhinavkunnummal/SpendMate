import { Router, Request, Response, NextFunction } from 'express';
import { authenticate } from '../../common/middleware/auth';
import { TripModel } from './trip.model';
import { UserModel } from '../users/user.model';
import { ItineraryDayModel } from '../itineraries/itinerary.model';
import { sendSuccess } from '../../common/response';
import { NotFoundError, AppError } from '../../common/errors';
import mongoose from 'mongoose';

const router = Router();
router.use(authenticate);

// Get user trips
router.get('/', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const userId = req.user!.userId;
    let trips = await TripModel.find({
      $or: [
        { creatorId: userId },
        { 'members.userId': userId },
      ],
    }).sort({ startDate: -1 });

    // Seed default Manali trip if none exists
    if (trips.length === 0) {
      const user = await UserModel.findById(userId);
      const creatorName = user?.name || req.user?.name || user?.phoneNumber || 'Organizer (You)';
      const userObjectId = new mongoose.Types.ObjectId(userId);
      const defaultTrip = await TripModel.create({
        creatorId: userObjectId,
        title: 'Manali Snow Expedition',
        destination: 'Manali, Himachal Pradesh',
        startDate: new Date('2026-11-18'),
        endDate: new Date('2026-11-24'),
        currency: 'INR',
        totalBudgetPaise: 8000000, // ₹80,000.00
        totalSpentPaise: 4820000,  // ₹48,200.00
        status: 'active',
        members: [
          { userId: userObjectId, name: creatorName, role: 'admin', joinedAt: new Date() },
          { name: 'Aarav Sharma', role: 'member', joinedAt: new Date() },
          { name: 'Rohan Mehra', role: 'member', joinedAt: new Date() },
          { name: 'Pooja Nair', role: 'member', joinedAt: new Date() },
        ],
      });

      // Seed itinerary for Manali
      await ItineraryDayModel.create([
        {
          tripId: defaultTrip._id,
          dayNumber: 1,
          date: new Date('2026-11-18'),
          activities: [
            { title: 'Depart from Delhi Airport / Volvo Pickup', time: '07:30 PM', location: 'Majnu Ka Tilla', isCompleted: false },
            { title: 'Overnight transit to Himachal', time: '10:00 PM', isCompleted: false },
          ],
        },
        {
          tripId: defaultTrip._id,
          dayNumber: 2,
          date: new Date('2026-11-19'),
          activities: [
            { title: 'Check in to Old Manali Riverside Cottage', time: '09:00 AM', location: 'Old Manali', isCompleted: false },
            { title: 'Café hopping & Local Cider Tasting', time: '01:00 PM', location: 'Café 1947', isCompleted: false },
            { title: 'Hadimba Devi Temple visit', time: '04:30 PM', isCompleted: false },
          ],
        },
      ]);

      trips = [defaultTrip];
    }

    sendSuccess(res, { trips }, 'Trips retrieved successfully');
  } catch (error) {
    next(error);
  }
});

// Get single trip details & members
router.get('/:id', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const trip = await TripModel.findById(req.params.id);
    if (!trip) throw new NotFoundError('Trip not found');

    const itinerary = await ItineraryDayModel.find({ tripId: trip._id }).sort({ dayNumber: 1 });

    sendSuccess(res, { trip, itinerary }, 'Trip details retrieved');
  } catch (error) {
    next(error);
  }
});

// Create new trip
router.post('/', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const userId = req.user!.userId;
    const { title, destination, startDate, endDate, totalBudgetPaise, memberNames } = req.body;

    if (!title || !destination || !startDate || !endDate) {
      throw new AppError('Title, destination, startDate, and endDate are required', 400);
    }

    const members: Array<{
      userId?: mongoose.Types.ObjectId;
      name: string;
      role: 'admin' | 'member';
      joinedAt: Date;
    }> = [
      { userId: new mongoose.Types.ObjectId(userId), name: req.user!.name || 'You', role: 'admin', joinedAt: new Date() },
    ];

    if (Array.isArray(memberNames)) {
      for (const mName of memberNames) {
        if (mName && typeof mName === 'string') {
          members.push({ name: mName.trim(), role: 'member', joinedAt: new Date() });
        }
      }
    }

    const trip = await TripModel.create({
      creatorId: new mongoose.Types.ObjectId(userId),
      title,
      destination,
      startDate: new Date(startDate),
      endDate: new Date(endDate),
      totalBudgetPaise: totalBudgetPaise || 5000000,
      totalSpentPaise: 0,
      status: 'active',
      members,
    });

    sendSuccess(res, { trip }, 'Trip created successfully', 201);
  } catch (error) {
    next(error);
  }
});

// Join an existing trip
router.post('/:id/join', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const userId = req.user!.userId;
    const user = await UserModel.findById(userId);
    const trip = await TripModel.findById(req.params.id);
    if (!trip) throw new NotFoundError('Trip not found');

    const alreadyJoined = trip.members.some(
      (m) => m.userId?.toString() === userId || (user?.phoneNumber && m.phoneNumber === user.phoneNumber)
    );

    if (!alreadyJoined) {
      trip.members.push({
        userId: new mongoose.Types.ObjectId(userId),
        name: user?.name || req.user?.name || user?.phoneNumber || 'New Member',
        phoneNumber: user?.phoneNumber,
        role: 'member',
        joinedAt: new Date(),
      });
      await trip.save();
    }

    sendSuccess(res, { trip }, 'Joined trip successfully');
  } catch (error) {
    next(error);
  }
});

// Add member by name/phone to trip
router.post('/:id/members', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { name, phoneNumber } = req.body;
    if (!name) throw new AppError('Member name is required', 400);

    const trip = await TripModel.findById(req.params.id);
    if (!trip) throw new NotFoundError('Trip not found');

    trip.members.push({
      name: name.trim(),
      phoneNumber: phoneNumber ? phoneNumber.trim() : undefined,
      role: 'member',
      joinedAt: new Date(),
    });
    await trip.save();

    sendSuccess(res, { trip }, 'Member added to trip successfully');
  } catch (error) {
    next(error);
  }
});

export const tripRouter = router;
