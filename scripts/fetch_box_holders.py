from brownie import NFTBoxesBox, web3
import csv
import numpy

def main():
    boxId = 2
    seedStr = '0x4f22a72b37e5acea8fc863522419e05e71bc9947bd0559995ee58702533bbb44'
    byteSeed = web3.toBytes(hexstr=seedStr)
    seed  = web3.soliditySha3(['bytes32'], [byteSeed])
    seedInt = web3.toInt(seed)
    box = NFTBoxesBox.at('0x067ab2FbdBED63401aF802d1DD786E6D83b0ff1B')
    print(f'Box contract at {box.address}\nFetching holders of box edition {boxId}...')
    ids = 6
    # event BoxBought(uint256 indexed boxMould, uint256 boxEdition, uint256 tokenId);
    box_contract = web3.eth.contract(address=box.address, abi=box.abi)
    filt = box_contract.events.BoxBought.createFilter(fromBlock=0, toBlock= 'latest', argument_filters={'boxMould':boxId})
    res = filt.get_all_entries()
    holders = [box.ownerOf(e.args.tokenId) for e in res]
    print(f'Box holders fetched. Size: {len(holders)}\nExecuting distribution from initial seed: {seedStr}')
    dissArr = []
    for i in range(ids):
        dissArr.append([h for h in holders])
    winnerArray = []
    for i in range(len(holders)):
        tempWinnerArray = []
        for j in range(ids):
            indexWinner = seedInt % len(dissArr[j])
            winner = dissArr[j][indexWinner]
            (seed, seedInt) = newSeed(seed, web3)
            tempWinnerArray.append(winner)
            dissArr[j].pop(indexWinner)
        winnerArray.append([w for w in tempWinnerArray])
        tempWinnerArray.clear()
    print(f'Distribution finished, writing data onto boxHolders_{boxId}.csv...')
    wtr = csv.writer(open (f'boxHolders_{boxId}.csv', 'w'), delimiter=',', lineterminator='\n')
    print(f'winner array length is {len(winnerArray)}')
    wtr.writerows(winnerArray)
    print('done')

def newSeed(seed, web3):
    seed = web3.soliditySha3(['bytes32'], [seed])
    return (seed, web3.toInt(seed))
