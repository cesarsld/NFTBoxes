from brownie import NFTBoxesBox, accounts, Wei
import csv

def main():
    user = accounts.load('moist')

    boxId = 1
    #  NEEDS TO BE CHANGED IF SCRIPTS FUCKS UP
    offset = 0
    box = NFTBoxesBox.at('0xB9134aef577b7cb43B03856E308ebDC80d51E126')
    dissArr = []
    ids = [1,2,3,4,5,6,7,8,9] # this line would be ids = [1, 2, 3, 4, 5, 6, 7] and be changed each month
    with open(f'boxHolders_{boxId}.csv') as csvfile:
        reader = csv.reader(csvfile)
        for row in reader:
            dissArr.append(row)

    batchSize = 50 // len(dissArr[0])
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
        box.distributeOffchain(boxId, users, ids,{'from':user})
