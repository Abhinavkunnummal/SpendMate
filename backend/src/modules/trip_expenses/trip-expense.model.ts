import mongoose, { Schema, Document } from 'mongoose';

export interface IContributor {
  memberId: string;
  name: string;
  amountPaise: number;
}

export interface ISplitShare {
  memberId: string;
  name: string;
  sharePaise: number;
  percentage?: number;
}

export interface ITripExpense extends Document {
  _id: mongoose.Types.ObjectId;
  tripId: mongoose.Types.ObjectId;
  createdBy: mongoose.Types.ObjectId;
  description: string;
  amountPaise: number;
  category: string;
  paidBy: IContributor[];
  splitType: 'equal' | 'exact' | 'percentage';
  splits: ISplitShare[];
  date: Date;
  receiptUrl?: string;
  notes?: string;
  createdAt: Date;
  updatedAt: Date;
}

const ContributorSchema = new Schema<IContributor>({
  memberId: { type: String, required: true },
  name: { type: String, required: true },
  amountPaise: { type: Number, required: true },
});

const SplitShareSchema = new Schema<ISplitShare>({
  memberId: { type: String, required: true },
  name: { type: String, required: true },
  sharePaise: { type: Number, required: true },
  percentage: { type: Number },
});

const TripExpenseSchema = new Schema<ITripExpense>(
  {
    tripId: {
      type: Schema.Types.ObjectId,
      ref: 'Trip',
      required: true,
      index: true,
    },
    createdBy: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    description: {
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
      default: 'General',
    },
    paidBy: {
      type: [ContributorSchema],
      required: true,
      validate: [
        (val: IContributor[]) => val.length > 0,
        'At least one contributor is required',
      ],
    },
    splitType: {
      type: String,
      enum: ['equal', 'exact', 'percentage'],
      default: 'equal',
    },
    splits: {
      type: [SplitShareSchema],
      required: true,
      validate: [
        (val: ISplitShare[]) => val.length > 0,
        'At least one participant split is required',
      ],
    },
    date: {
      type: Date,
      default: Date.now,
      index: true,
    },
    receiptUrl: {
      type: String,
    },
    notes: {
      type: String,
      trim: true,
    },
  },
  {
    timestamps: true,
  }
);

export const TripExpenseModel = mongoose.model<ITripExpense>('TripExpense', TripExpenseSchema);
