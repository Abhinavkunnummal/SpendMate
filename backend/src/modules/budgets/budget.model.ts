import mongoose, { Schema, Document } from 'mongoose';

export interface IBudget extends Document {
  _id: mongoose.Types.ObjectId;
  userId: mongoose.Types.ObjectId;
  categoryId: mongoose.Types.ObjectId;
  limitPaise: number;
  spentPaise: number;
  monthYear: string; // e.g. "2026-11"
  alertThresholdPercentage: number;
  createdAt: Date;
  updatedAt: Date;
}

const BudgetSchema = new Schema<IBudget>(
  {
    userId: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    categoryId: {
      type: Schema.Types.ObjectId,
      ref: 'Category',
      required: true,
      index: true,
    },
    limitPaise: {
      type: Number,
      required: true,
    },
    spentPaise: {
      type: Number,
      default: 0,
    },
    monthYear: {
      type: String,
      required: true,
      index: true,
    },
    alertThresholdPercentage: {
      type: Number,
      default: 80,
    },
  },
  {
    timestamps: true,
  }
);

BudgetSchema.index({ userId: 1, monthYear: 1, categoryId: 1 }, { unique: true });

export const BudgetModel = mongoose.model<IBudget>('Budget', BudgetSchema);
