import { DebtMinimizer, MemberNetBalance } from './debt-minimizer';

describe('Debt Minimizer & Multi-Payer Split Engine', () => {
  it('correctly splits multi-payer ticket expense equally among 4 friends', () => {
    const totalExpensePaise = 56000; // ₹560.00
    const contributors = [
      { memberId: 'A', amountPaise: 40000 }, // A paid ₹400
      { memberId: 'C', amountPaise: 16000 }, // C paid ₹160
    ];

    // Validate multi-payer contributions
    const isValid = DebtMinimizer.validateMultiPayer(totalExpensePaise, contributors);
    expect(isValid).toBe(true);

    // Split equally among A, B, C, D
    const participants = ['A', 'B', 'C', 'D'];
    const shares = DebtMinimizer.splitEqually(totalExpensePaise, participants);

    expect(shares.get('A')).toBe(14000); // ₹140.00
    expect(shares.get('B')).toBe(14000);
    expect(shares.get('C')).toBe(14000);
    expect(shares.get('D')).toBe(14000);

    // Total shares must equal total expense exactly
    let totalShares = 0;
    shares.forEach((val) => (totalShares += val));
    expect(totalShares).toBe(totalExpensePaise);
  });

  it('correctly handles remainder paise distribution without rounding errors', () => {
    const totalExpensePaise = 10000; // ₹100.00 split among 3 people
    const participants = ['P1', 'P2', 'P3'];
    const shares = DebtMinimizer.splitEqually(totalExpensePaise, participants);

    expect(shares.get('P1')).toBe(3334); // gets 1 remainder paise
    expect(shares.get('P2')).toBe(3333);
    expect(shares.get('P3')).toBe(3333);

    let sum = 0;
    shares.forEach((v) => (sum += v));
    expect(sum).toBe(10000);
  });

  it('solves minimal group payments matching user specification', () => {
    // Specification from prompt:
    // A receives ₹960 (+96000 paise)
    // B receives ₹160 (+16000 paise)
    // C owes ₹480 (-48000 paise)
    // D owes ₹640 (-64000 paise)
    const balances: MemberNetBalance[] = [
      { memberId: 'A', name: 'Member A', netBalancePaise: 96000 },
      { memberId: 'B', name: 'Member B', netBalancePaise: 16000 },
      { memberId: 'C', name: 'Member C', netBalancePaise: -48000 },
      { memberId: 'D', name: 'Member D', netBalancePaise: -64000 },
    ];

    const settlements = DebtMinimizer.calculateSettlements(balances);

    // Total payments should be 3
    expect(settlements.length).toBe(3);

    // D owes the most (64000), A is owed the most (96000)
    // D pays A 64000, or D pays A 48000 + B 16000, and C pays A 48000
    const totalSettled = settlements.reduce((acc, s) => acc + s.amountPaise, 0);
    expect(totalSettled).toBe(112000); // 96000 + 16000 = 112000 paise

    // Verify all debts are paid off:
    // D should pay a total of 64000 paise
    const dPayments = settlements
      .filter((s) => s.fromMemberId === 'D')
      .reduce((acc, s) => acc + s.amountPaise, 0);
    expect(dPayments).toBe(64000);

    // C should pay a total of 48000 paise
    const cPayments = settlements
      .filter((s) => s.fromMemberId === 'C')
      .reduce((acc, s) => acc + s.amountPaise, 0);
    expect(cPayments).toBe(48000);

    // A should receive a total of 96000 paise
    const aReceived = settlements
      .filter((s) => s.toMemberId === 'A')
      .reduce((acc, s) => acc + s.amountPaise, 0);
    expect(aReceived).toBe(96000);

    // B should receive a total of 16000 paise
    const bReceived = settlements
      .filter((s) => s.toMemberId === 'B')
      .reduce((acc, s) => acc + s.amountPaise, 0);
    expect(bReceived).toBe(16000);
  });
});
