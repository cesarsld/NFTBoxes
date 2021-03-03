from brownie import NFTBoxesBox, accounts, Wei
import csv

def main():
    user = accounts.load('box')

    boxId = 1
    #  NEEDS TO BE CHANGED IF SCRIPT CRASHES
    offset = 79
    box = NFTBoxesBox.at('0x5f8061f9d6a2bb4688f46491cca7658e214e2cb6')
    dissArr = []
    ids = [1,2,3,4,5,6,7,8,9,10] # this line would be ids = [1, 2, 3, 4, 5, 6, 7] and be changed each month
    with open(f'boxHolders_{boxId}.csv') as csvfile:
        reader = csv.reader(csvfile)
        for row in reader:
            dissArr.append(row)

    batchSize = 20 // len(dissArr[0])
    loops = len(dissArr) // batchSize + (1 if len(dissArr) % batchSize > 0 else 0)
    print(f'Batch size: {batchSize} - loops: {loops}')
    for i in range(offset, loops):
        print(f'Sending batch #{i + 1} out of {loops}')
        if i == loops - 1:
            print(f'range[{i * batchSize}:end]')
            users = dissArr[i * batchSize:]
        else:
            print(f'range[{i * batchSize}:{(i + 1) * batchSize}]')
            users = dissArr[i * batchSize : (i + 1) * batchSize]
        box.distributeOffchain(boxId, users, ids,{'from':user, 'gas_price': '145 gwei'})
