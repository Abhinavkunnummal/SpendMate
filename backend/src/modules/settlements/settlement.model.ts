import mongoose, { Schema, Document } from 'mongoose';

export interface ISettlementRecord extends Document {
  _id: mongoose.Types.ObjectId;
  tripId: mongoose.Types.ObjectId;
  fromMemberId: string;
  fromName: string;
  toMemberId: string;
  toName: string;
  amountPaise: number;
  status: 'pending' | 'completed' | 'verified';
  paymentMethod?: string;
  transactionReference?: string;
  proofImageUrl?: string;
  settledAt?: Date;
  createdAt: Date;
  updatedAt: Date;
}

const SettlementSchema = new Schema<ISettlementRecord>(
  {
    tripId: {
      type: Schema.Types.ObjectId,
      ref: 'Trip',
      required: true,
      index: true,
    },
    fromMemberId: { type: String, required: true },
    fromName: { type: String, required: true },
    toMemberId: { type: String, required: true },
    toName: { type: String, required: true },
    amountPaise: { type: Number, required: true },
    status: {
      type: String,
      enum: ['pending', 'completed', 'verified'],
      default: 'pending',
    },
    paymentMethod: { type: String, default: 'UPI' },
    transactionReference: { type: String },
    proofImageUrl: { type: String },
    settledAt: { type: Date },
  },
  {
    timestamps: true,
  }
);

export const SettlementModel = mongoose.model<ISettlementRecord>('Settlement', SettlementSchema);
