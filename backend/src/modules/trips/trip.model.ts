import mongoose, { Schema, Document } from 'mongoose';

export interface ITripMember {
  _id?: mongoose.Types.ObjectId;
  userId?: mongoose.Types.ObjectId;
  name: string;
  phoneNumber?: string;
  avatarUrl?: string;
  role: 'admin' | 'member';
  joinedAt: Date;
}

export interface ITrip extends Document {
  _id: mongoose.Types.ObjectId;
  creatorId: mongoose.Types.ObjectId;
  title: string;
  destination: string;
  startDate: Date;
  endDate: Date;
  coverImageUrl?: string;
  currency: string;
  totalBudgetPaise: number;
  totalSpentPaise: number;
  members: ITripMember[];
  status: 'planning' | 'active' | 'completed';
  createdAt: Date;
  updatedAt: Date;
}

const TripMemberSchema = new Schema<ITripMember>({
  userId: { type: Schema.Types.ObjectId, ref: 'User' },
  name: { type: String, required: true },
  phoneNumber: { type: String },
  avatarUrl: { type: String },
  role: { type: String, enum: ['admin', 'member'], default: 'member' },
  joinedAt: { type: Date, default: Date.now },
});

const TripSchema = new Schema<ITrip>(
  {
    creatorId: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    title: {
      type: String,
      required: true,
      trim: true,
    },
    destination: {
      type: String,
      required: true,
      trim: true,
    },
    startDate: {
      type: Date,
      required: true,
    },
    endDate: {
      type: Date,
      required: true,
    },
    coverImageUrl: {
      type: String,
    },
    currency: {
      type: String,
      default: 'INR',
    },
    totalBudgetPaise: {
      type: Number,
      default: 10000000, // ₹1,00,000.00
    },
    totalSpentPaise: {
      type: Number,
      default: 0,
    },
    members: [TripMemberSchema],
    status: {
      type: String,
      enum: ['planning', 'active', 'completed'],
      default: 'active',
    },
  },
  {
    timestamps: true,
  }
);

export const TripModel = mongoose.model<ITrip>('Trip', TripSchema);
