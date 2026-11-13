import mongoose, { Schema, Document } from 'mongoose';

export interface IRecurringExpense extends Document {
  _id: mongoose.Types.ObjectId;
  userId: mongoose.Types.ObjectId;
  name: string;
  amountPaise: number;
  category: string;
  frequency: 'daily' | 'weekly' | 'monthly' | 'yearly';
  nextBillingDate: Date;
  walletId?: mongoose.Types.ObjectId;
  color: string;
  icon: string;
  isActive: boolean;
  createdAt: Date;
  updatedAt: Date;
}

const RecurringExpenseSchema = new Schema<IRecurringExpense>(
  {
    userId: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    name: {
      type: String,
      required: true,
      trim: true,
    },
    amountPaise: {
      type: Number,
      required: true,
    },
    category: {
      type: String,
      default: 'Subscriptions',
    },
    frequency: {
      type: String,
      enum: ['daily', 'weekly', 'monthly', 'yearly'],
      default: 'monthly',
    },
    nextBillingDate: {
      type: Date,
      required: true,
    },
    walletId: {
      type: Schema.Types.ObjectId,
      ref: 'Wallet',
    },
    color: {
      type: String,
      default: '#8B5CF6',
    },
    icon: {
      type: String,
      default: 'subscriptions',
    },
    isActive: {
      type: Boolean,
      default: true,
    },
  },
  {
    timestamps: true,
  }
);

export const RecurringExpenseModel = mongoose.model<IRecurringExpense>('RecurringExpense', RecurringExpenseSchema);
