import { Provider, makeContract } from '@clarigen/core';
import { testProvider, mockReadOnlyFunction, assert, expect } from '@clarigen/test';

import { NFT_Trait } from './path-to-your-contracts'; // Replace with the correct path

describe('NFT Trait Tests', () => {
  let nftTrait: NFT_Trait;

  beforeEach(() => {
    const provider: Provider = testProvider();
    nftTrait = makeContract(provider, NFT_Trait);
  });

  it('should mint NFT successfully', async () => {
    // Mock the mint function
    const mockMint = mockReadOnlyFunction(NFT_Trait.mint, 1); // Assuming the mint function returns the token ID

    // Call your trait function
    const result = await nftTrait.mint('recipient-address');

    // Check that the function was called with the correct parameters
    expect(mockMint).toHaveBeenCalledWith('recipient-address');

    // Check the result
    expect(result).toEqual(1);
  });

  it('should get owner of NFT', async () => {
    // Mock the get-owner function
    const mockGetOwner = mockReadOnlyFunction(NFT_Trait.getOwner, 'owner-address');

    // Call your trait function
    const result = await nftTrait.getOwner(1); // Assuming the token ID is 1

    // Check that the function was called with the correct parameters
    expect(mockGetOwner).toHaveBeenCalledWith(1);

    // Check the result
    expect(result).toEqual('owner-address');
  });
});
