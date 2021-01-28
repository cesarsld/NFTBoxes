from brownie import NFTBoxes, JOYtoys, accounts, chain, interface, Wei, web3
from time import sleep

def main():
    # user2 = accounts.load('owl')
    user = accounts.load('moist')
    # box = NFTBoxes.at('0xfa4Ff49c6ab0Ad4Fc2f5729F2807a28D497Db5c3')
    # joy = JOYtoys.at('0x4de525edb160dc7b773cd249554d8ba98c550d07')
    box = NFTBoxes.deploy({'from':user}, publish_source=False)
    # joy = JOYtoys.deploy({'from':user}, publish_source=False)
    # joy = JOYtoys.at('0x728dA69402B28048F96ab9564f577Be232952957')
    box.transferOwnership('0x63a9dbCe75413036B2B778E670aaBd4493aAF9F3', {'from':user})
    # joy.transferOwnership('0x63a9dbCe75413036B2B778E670aaBd4493aAF9F3', {'from':user})
    # joy.setCaller(box, True, {'from':user})
    # joy.createJOYtoy("c0ffee", "someType", "over 9000", "toy", "fun", 100, True, 0, 0, {'from':user})
    # joy.setCaller(user, True, {'from':user})
    # joy.JOYtoyMachineFor(1, user, {'from':user})
    # joy.JOYtoyMachineFor(1, user, {'from':user})
    # joy.JOYtoyMachineFor(1, user, {'from':user})
    # box.setVendingMachine(joy, {'from': user})
    # box.createBoxMould(40, Wei('0 ether'), [11, 12, 13, 14, 15, 16, 17, 18, 19, 20], [], [], "This is a test box", {'from':user})
    # box.buyManyBoxes(1, 20, {'from':user})
    # box.buyManyBoxes(1, 20, {'from':user2})
    # for i in range(10):
    #     joy.createJOYtoy(f'c0ffee{i + 11}', "someType", "over 9000", "toy", "fun", 40, True, 0, 0, {'from':user})
