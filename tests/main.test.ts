import { Provider, makeContracts } from '@clarigen/core';
import { TestProvider, mockReadOnlyFunction, assert, expect } from '@clarigen/test';

import { SIP010Token, FT_Trait } from './ft-trait.test'; // Replace with the correct path
import { beforeEach, describe } from 'vitest';

describe('SIP010Token Smart Contract Tests', () => {
  let sip010Token: SIP010Token;

  beforeEach(() => {
    const provider: Provider = testProvider();
    sip010Token = makeContracts(provider, SIP010Token);
  });

  it('should transfer tokens successfully', async () => {
    // Mock the ft-transfer? function in the FT_Trait
    const mockTransfer = mockReadOnlyFunction(FT_Trait.transfer, true);

    // Call your contract function
    const result = await sip010Token.transfer(100, 'recipient-address', 'sender-address');

    // Check that the function was called with the correct parameters
    expect(mockTransfer).toHaveBeenCalledWith(100, 'recipient-address', 'sender-address');

    // Check the result
    assert.isTrue(result);
  });

  it('should handle transfer failure', async () => {
    // Mock the ft-transfer? function in the FT_Trait to return false
    const mockTransfer = mockReadOnlyFunction(FT_Trait.transfer, false);

    // Call your contract function
    const result = await sip010Token.transfer(50, 'recipient-address', 'sender-address');

    // Check that the function was called with the correct parameters
    expect(mockTransfer).toHaveBeenCalledWith(50, 'recipient-address', 'sender-address');

    // Check the result
    assert.isFalse(result);
  });
});

export { FT_Trait };
