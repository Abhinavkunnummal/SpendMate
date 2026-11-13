import mongoose, { Schema, Document } from 'mongoose';

export interface ITransaction extends Document {
  _id: mongoose.Types.ObjectId;
  userId: mongoose.Types.ObjectId;
  walletId: mongoose.Types.ObjectId;
  categoryId: mongoose.Types.ObjectId;
  amountPaise: number;
  type: 'expense' | 'income' | 'transfer';
  description: string;
  notes?: string;
  date: Date;
  receiptUrl?: string;
  tags: string[];
  isRecurring: boolean;
  recurringRuleId?: mongoose.Types.ObjectId;
  createdAt: Date;
  updatedAt: Date;
}

const TransactionSchema = new Schema<ITransaction>(
  {
    userId: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    walletId: {
      type: Schema.Types.ObjectId,
      ref: 'Wallet',
      required: true,
      index: true,
    },
    categoryId: {
      type: Schema.Types.ObjectId,
      ref: 'Category',
      required: true,
      index: true,
    },
    amountPaise: {
      type: Number,
      required: true,
    },
    type: {
      type: String,
      enum: ['expense', 'income', 'transfer'],
      required: true,
    },
    description: {
      type: String,
      required: true,
      trim: true,
    },
    notes: {
      type: String,
      trim: true,
    },
    date: {
      type: Date,
      required: true,
      default: Date.now,
      index: true,
    },
    receiptUrl: {
      type: String,
    },
    tags: {
      type: [String],
      default: [],
    },
    isRecurring: {
      type: Boolean,
      default: false,
    },
    recurringRuleId: {
      type: Schema.Types.ObjectId,
      ref: 'RecurringExpense',
    },
  },
  {
    timestamps: true,
  }
);

TransactionSchema.index({ userId: 1, date: -1 });

export const TransactionModel = mongoose.model<ITransaction>('Transaction', TransactionSchema);
