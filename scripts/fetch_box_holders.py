from brownie import NFTBoxesBox, web3
import csv

def main():
    boxId = 1
    seedStr = '0xc63e18417049d1aed1dc4bea9f25838f3423fcd552bb316546f6b92e4979065c'
    byteSeed = web3.toBytes(hexstr=seedStr)
    seed  = web3.soliditySha3(['bytes32'], [byteSeed])
    seedInt = web3.toInt(seed)
    box = NFTBoxesBox.at('0xB9134aef577b7cb43B03856E308ebDC80d51E126')
    print(f'Box contract at {box.address}\nFetching holders of box edition {boxId}...')
    ids = 9
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
    for x in winnerArray:
        wtr.writerow (x)
    print('done')

def newSeed(seed, web3):
    seed = web3.soliditySha3(['bytes32'], [seed])
    return (seed, web3.toInt(seed))