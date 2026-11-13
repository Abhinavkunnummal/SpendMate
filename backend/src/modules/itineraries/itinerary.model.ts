import mongoose, { Schema, Document } from 'mongoose';

export interface IItineraryActivity {
  _id?: mongoose.Types.ObjectId;
  title: string;
  time?: string;
  location?: string;
  notes?: string;
  estimatedCostPaise?: number;
  isCompleted: boolean;
}

export interface IItineraryDay extends Document {
  _id: mongoose.Types.ObjectId;
  tripId: mongoose.Types.ObjectId;
  dayNumber: number;
  date: Date;
  activities: IItineraryActivity[];
  createdAt: Date;
  updatedAt: Date;
}

const ItineraryActivitySchema = new Schema<IItineraryActivity>({
  title: { type: String, required: true },
  time: { type: String },
  location: { type: String },
  notes: { type: String },
  estimatedCostPaise: { type: Number, default: 0 },
  isCompleted: { type: Boolean, default: false },
});

const ItineraryDaySchema = new Schema<IItineraryDay>(
  {
    tripId: {
      type: Schema.Types.ObjectId,
      ref: 'Trip',
      required: true,
      index: true,
    },
    dayNumber: {
      type: Number,
      required: true,
    },
    date: {
      type: Date,
      required: true,
    },
    activities: [ItineraryActivitySchema],
  },
  {
    timestamps: true,
  }
);

export const ItineraryDayModel = mongoose.model<IItineraryDay>('ItineraryDay', ItineraryDaySchema);
