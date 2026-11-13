export interface MemberNetBalance {
  memberId: string;
  name: string;
  netBalancePaise: number; // positive = creditor (gets money), negative = debtor (owes money)
}

export interface SuggestedSettlement {
  fromMemberId: string;
  fromName: string;
  toMemberId: string;
  toName: string;
  amountPaise: number;
}

export class DebtMinimizer {
  /**
   * Distributes totalExpensePaise equally among participantIds,
   * deterministically allocating any remainder paise so that
   * sum(shares) === totalExpensePaise exactly.
   */
  static splitEqually(totalExpensePaise: number, participantIds: string[]): Map<string, number> {
    if (participantIds.length === 0) {
      throw new Error('Participant list cannot be empty');
    }

    const n = participantIds.length;
    const baseShare = Math.floor(totalExpensePaise / n);
    const remainder = totalExpensePaise % n;

    const shares = new Map<string, number>();
    participantIds.forEach((id, index) => {
      // Allocate 1 extra paise to the first `remainder` participants
      const share = baseShare + (index < remainder ? 1 : 0);
      shares.set(id, share);
    });

    return shares;
  }

  /**
   * Validates multi-payer contributions against total expense
   */
  static validateMultiPayer(
    totalExpensePaise: number,
    contributors: Array<{ memberId: string; amountPaise: number }>
  ): boolean {
    const totalContributed = contributors.reduce((acc, c) => acc + c.amountPaise, 0);
    return totalContributed === totalExpensePaise;
  }

  /**
   * Solves minimal cash transfers to settle all group debts.
   * Runs in O(N log N) using greedy matching of highest debtor and highest creditor.
   */
  static calculateSettlements(balances: MemberNetBalance[]): SuggestedSettlement[] {
    // Separate into debtors and creditors (ignoring settled zero balances)
    const debtors: Array<{ memberId: string; name: string; amount: number }> = [];
    const creditors: Array<{ memberId: string; name: string; amount: number }> = [];

    let totalSum = 0;
    for (const b of balances) {
      totalSum += b.netBalancePaise;
      if (b.netBalancePaise < 0) {
        debtors.push({
          memberId: b.memberId,
          name: b.name,
          amount: Math.abs(b.netBalancePaise),
        });
      } else if (b.netBalancePaise > 0) {
        creditors.push({
          memberId: b.memberId,
          name: b.name,
          amount: b.netBalancePaise,
        });
      }
    }

    // Conservation check: total debts must match total credits
    if (Math.abs(totalSum) > balances.length) {
      throw new Error(`Net group balances do not sum to 0 (imbalance: ${totalSum} paise)`);
    }

    // Sort descending by amount
    debtors.sort((a, b) => b.amount - a.amount);
    creditors.sort((a, b) => b.amount - a.amount);

    const settlements: SuggestedSettlement[] = [];
    let dIdx = 0;
    let cIdx = 0;

    while (dIdx < debtors.length && cIdx < creditors.length) {
      const debtor = debtors[dIdx];
      const creditor = creditors[cIdx];

      const settlementAmount = Math.min(debtor.amount, creditor.amount);

      if (settlementAmount > 0) {
        settlements.push({
          fromMemberId: debtor.memberId,
          fromName: debtor.name,
          toMemberId: creditor.memberId,
          toName: creditor.name,
          amountPaise: settlementAmount,
        });
      }

      debtor.amount -= settlementAmount;
      creditor.amount -= settlementAmount;

      if (debtor.amount === 0) dIdx++;
      if (creditor.amount === 0) cIdx++;
    }

    return settlements;
  }
}
