import mongoose, { Schema, Document } from 'mongoose';

export interface IWallet extends Document {
  _id: mongoose.Types.ObjectId;
  userId: mongoose.Types.ObjectId;
  name: string;
  type: 'bank' | 'cash' | 'credit_card' | 'upi' | 'wallet';
  balancePaise: number;
  accountNumberLast4?: string;
  color: string;
  icon: string;
  isDefault: boolean;
  createdAt: Date;
  updatedAt: Date;
}

const WalletSchema = new Schema<IWallet>(
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
    type: {
      type: String,
      enum: ['bank', 'cash', 'credit_card', 'upi', 'wallet'],
      default: 'bank',
    },
    balancePaise: {
      type: Number,
      required: true,
      default: 0,
    },
    accountNumberLast4: {
      type: String,
      trim: true,
    },
    color: {
      type: String,
      default: '#16A878',
    },
    icon: {
      type: String,
      default: 'account_balance_wallet',
    },
    isDefault: {
      type: Boolean,
      default: false,
    },
  },
  {
    timestamps: true,
  }
);

export const WalletModel = mongoose.model<IWallet>('Wallet', WalletSchema);
