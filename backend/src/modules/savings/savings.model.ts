import mongoose, { Schema, Document } from 'mongoose';

export interface ISavingsGoal extends Document {
  _id: mongoose.Types.ObjectId;
  userId: mongoose.Types.ObjectId;
  name: string;
  targetAmountPaise: number;
  currentAmountPaise: number;
  targetDate?: Date;
  icon: string;
  color: string;
  status: 'in_progress' | 'completed' | 'paused';
  createdAt: Date;
  updatedAt: Date;
}

const SavingsGoalSchema = new Schema<ISavingsGoal>(
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
    targetAmountPaise: {
      type: Number,
      required: true,
    },
    currentAmountPaise: {
      type: Number,
      default: 0,
    },
    targetDate: {
      type: Date,
    },
    icon: {
      type: String,
      default: 'savings',
    },
    color: {
      type: String,
      default: '#16A878',
    },
    status: {
      type: String,
      enum: ['in_progress', 'completed', 'paused'],
      default: 'in_progress',
    },
  },
  {
    timestamps: true,
  }
);

export const SavingsGoalModel = mongoose.model<ISavingsGoal>('SavingsGoal', SavingsGoalSchema);
