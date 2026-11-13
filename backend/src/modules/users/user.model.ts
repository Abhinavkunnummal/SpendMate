import mongoose, { Schema, Document } from 'mongoose';

export interface IUser extends Document {
  _id: mongoose.Types.ObjectId;
  phoneNumber: string;
  name?: string;
  email?: string;
  avatarUrl?: string;
  currency: string;
  themePreference: 'light' | 'dark' | 'system';
  monthlyBudgetPaise: number;
  notificationSettings: {
    push: boolean;
    email: boolean;
    tripReminders: boolean;
    budgetAlerts: boolean;
  };
  isProfileCompleted: boolean;
  createdAt: Date;
  updatedAt: Date;
}

const UserSchema = new Schema<IUser>(
  {
    phoneNumber: {
      type: String,
      required: true,
      unique: true,
      trim: true,
      index: true,
    },
    name: {
      type: String,
      trim: true,
      default: '',
    },
    email: {
      type: String,
      trim: true,
      lowercase: true,
      sparse: true,
    },
    avatarUrl: {
      type: String,
      default: '',
    },
    currency: {
      type: String,
      default: 'INR',
      uppercase: true,
    },
    themePreference: {
      type: String,
      enum: ['light', 'dark', 'system'],
      default: 'system',
    },
    monthlyBudgetPaise: {
      type: Number,
      default: 5000000, // Default ₹50,000.00
    },
    notificationSettings: {
      push: { type: Boolean, default: true },
      email: { type: Boolean, default: true },
      tripReminders: { type: Boolean, default: true },
      budgetAlerts: { type: Boolean, default: true },
    },
    isProfileCompleted: {
      type: Boolean,
      default: false,
    },
  },
  {
    timestamps: true,
  }
);

export const UserModel = mongoose.model<IUser>('User', UserSchema);
