import { Provider, makeContract } from '@clarigen/core';
import { testProvider, mockReadOnlyFunction, assert, expect } from '@clarigen/test';

import { FT_Trait } from './main.test'; // Replace with the correct path

describe('FT Trait Tests', () => {
  let ftTrait: FT_Trait;

  beforeEach(() => {
    const provider: Provider = testProvider();
    ftTrait = makeContract(provider, FT_Trait);
  });

  it('should transfer tokens successfully', async () => {
    // Mock the transfer function
    const mockTransfer = mockReadOnlyFunction(FT_Trait.transfer, true);

    // Call your trait function
    const result = await ftTrait.transfer(100, 'recipient-address', 'sender-address');

    // Check that the function was called with the correct parameters
    expect(mockTransfer).toHaveBeenCalledWith(100, 'recipient-address', 'sender-address');

    // Check the result
    assert.isTrue(result);
  });

  it('should handle transfer failure', async () => {
    // Mock the transfer function to return false
    const mockTransfer = mockReadOnlyFunction(FT_Trait.transfer, false);

    // Call your trait function
    const result = await ftTrait.transfer(50, 'recipient-address', 'sender-address');

    // Check that the function was called with the correct parameters
    expect(mockTransfer).toHaveBeenCalledWith(50, 'recipient-address', 'sender-address');

    // Check the result
    assert.isFalse(result);
  });
});
