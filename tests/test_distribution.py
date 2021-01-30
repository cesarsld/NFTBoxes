import pytest
import brownie
from brownie import Wei

def test_lock_buy(nftbox, minter, accounts):
    nftbox.createBoxMould(50, 50,  Wei('0.1 ether'), [], [], "This is a test box", "", "", "", "", {'from':minter})
    nftbox.createBoxMould(25, 50, Wei('.20 ether'), [], [], "This is a second test box", "", "", "", "", {'from':minter})
    u1 = accounts[0]
    u2 = accounts[1]
    with brownie.reverts("NFTBoxes: Box is locked"):
        nftbox.buyManyBoxes(1, 5, {'from':u1, "value": Wei("0.1 ether") * 5})
    with brownie.reverts("NFTBoxes: Box is locked"):
        nftbox.buyManyBoxes(2, 5, {'from':u1, "value": Wei("0.2 ether") * 5})
    nftbox.setLockOnBox(1, False, {'from':minter})
    nftbox.setLockOnBox(2, False, {'from':minter})
    nftbox.buyManyBoxes(1, 5, {'from':u1, "value": Wei("0.1 ether") * 5})
    nftbox.buyManyBoxes(2, 5, {'from':u1, "value": Wei("0.2 ether") * 5})


def test_authorised(nftbox, minter, accounts):
    nftbox.createBoxMould(50, 50,  Wei('0.1 ether'), [], [], "This is a test box", "", "", "", "", {'from':minter})
    nftbox.setLockOnBox(1, False, {'from':minter})
    with brownie.reverts("NFTBoxes: Not authorised to execute."):
        nftbox.closeBox(1, {'from':accounts[1]})
    nftbox.setCaller(accounts[1], True, {'from':minter})
    nftbox.closeBox(1, {'from':accounts[1]})

def test_toomany_boxes_at_once(nftbox, minter, accounts):
    nftbox.createBoxMould(50, 5,  Wei('0.1 ether'), [], [], "This is a test box", "", "", "", "", {'from':minter})
    nftbox.setLockOnBox(1, False, {'from':minter})
    with brownie.reverts("NFTBoxes: Cannot buy this many boxes."):
        nftbox.buyManyBoxes(1, 6, {'from':accounts[0], "value": Wei("0.1 ether") * 6})
    nftbox.buyManyBoxes(1, 5, {'from':accounts[0], "value": Wei("0.1 ether") * 5})


def test_seed(nftbox, minter, web3):
    seed = '0x6b81fc5c9ff7a165c1f5254bc7dff5280dbc1d7d6d2f16a3cb9de105b1b67569'
    byteSeed = web3.toBytes(hexstr=seed)
    for i in range(10):
        newSeed = nftbox._getNewSeed(seed)
        newByteSeed = web3.soliditySha3(['bytes32'], [seed])
        assert str(newSeed) == newByteSeed.hex()
        seed = str(newSeed)

def test_lock(nftbox, minter, accounts):
    nftbox.createBoxMould(50, 50,  Wei('0.1 ether'), [], [], "This is a test box", "", "", "", "", {'from':minter})
    nftbox.createBoxMould(25, 50, Wei('.20 ether'), [], [], "This is a second test box", "", "", "", "", {'from':minter})
    nftbox.setLockOnBox(1, False, {'from':minter})
    nftbox.setLockOnBox(2, False, {'from':minter})
    u1 = accounts[0]
    u2 = accounts[1]
    nftbox.buyManyBoxes(1, 5, {'from':u1, "value": Wei("0.1 ether") * 5})
    nftbox.buyManyBoxes(1, 1, {'from':u1, "value": Wei("0.1 ether")})
    nftbox.buyManyBoxes(1, 7, {'from':u1, "value": Wei("0.1 ether") * 7})
    nftbox.buyManyBoxes(2, 5, {'from':u1, "value": Wei("0.2 ether") * 5})

    nftbox.safeTransferFrom(u1, u2, 0, {'from':u1})
    assert nftbox.ownerOf(0) == u2
    nftbox.setLockOnBox(1, True, {'from':minter})
    with brownie.reverts("NFTBoxes: Box is locked"):
        nftbox.safeTransferFrom(u2, u1, 0, {'from':u2})
    with brownie.reverts("NFTBoxes: Box is locked"):
        nftbox.safeTransferFrom(u2, u1, 0, "", {'from':u2})
    with brownie.reverts("NFTBoxes: Box is locked"):
        nftbox.transferFrom(u2, u1, 0, {'from':u2})
    nftbox.setLockOnBox(1, False, {'from':minter})
    nftbox.safeTransferFrom(u2, u1, 0, {'from':u2})
    nftbox.safeTransferFrom(u1, u2, 0, "", {'from':u1})
    nftbox.transferFrom(u2, u1, 0, {'from':u2})


def test_box(nftbox, minter, accounts):
    nftbox.createBoxMould(50, 50, Wei('0.1 ether'), [], [], "This is a test box", "", "", "", "", {'from':minter})
    nftbox.createBoxMould(25, 50, Wei('.20 ether'), [], [], "This is a second test box", "", "", "", "", {'from':minter})
    nftbox.setLockOnBox(1, False, {'from':minter})
    nftbox.setLockOnBox(2, False, {'from':minter})
    u1 = accounts[0]
    u2 = accounts[1]
    nftbox.buyManyBoxes(1, 1, {'from':u1, "value": Wei("0.1 ether")})
    nftbox.buyManyBoxes(1, 1, {'from':u2, "value": Wei("0.1 ether")})
    nftbox.buyManyBoxes(2, 1, {'from':u1, "value": Wei("0.2 ether")})
    nftbox.buyManyBoxes(2, 1, {'from':u2, "value": Wei("0.2 ether")})
 
    assert nftbox.ownerOf(0) == u1
    assert nftbox.ownerOf(1) == u2

    assert nftbox.boxes(0) == (1, 1)
    assert nftbox.boxes(1) == (1, 2)
    assert nftbox.boxes(2) == (2, 1)
    assert nftbox.boxes(3) == (2, 2)

def test_box_editions(nftbox, minter, accounts):
    nftbox.createBoxMould(50, 50, Wei('0.1 ether'), [], [], "This is a test box", "", "", "", "", {'from':minter})
    nftbox.createBoxMould(25, 50, Wei('.20 ether'), [], [], "This is a second test box", "", "", "", "", {'from':minter})
    nftbox.setLockOnBox(1, False, {'from':minter})
    nftbox.setLockOnBox(2, False, {'from':minter})
    u1 = accounts[0]
    nftbox.buyManyBoxes(1, 5, {'from':u1, "value": Wei("0.1 ether") * 5})
    nftbox.buyManyBoxes(1, 1, {'from':u1, "value": Wei("0.1 ether")})
    nftbox.buyManyBoxes(1, 7, {'from':u1, "value": Wei("0.1 ether") * 7})
    nftbox.buyManyBoxes(2, 5, {'from':u1, "value": Wei("0.2 ether") * 5})

    for i in range(5):
        assert nftbox.boxes(i) == (1, i + 1)
    assert nftbox.boxes(5) == (1, 6)
    for i in range(6, 6 + 7):
        assert nftbox.boxes(i) == (1, i + 1)
    for i in range (13, 18):
        assert nftbox.boxes(i) == (2, i - 13 + 1)

def test_not_buyable_edition_many(nftbox, minter, accounts):
    nftbox.createBoxMould(5, 5, Wei('0.01 ether'), [], [], "This is a test box", "", "", "", "", {'from':minter})
    nftbox.setLockOnBox(1, False, {'from':minter})
    with brownie.reverts("NFTBoxes: Minting too many boxes."):
        nftbox.buyManyBoxes(1, 6, {'from':accounts[0], "value": Wei("0.01 ether") * 6})
    nftbox.buyManyBoxes(1, 3, {'from':accounts[0], "value": Wei("0.01 ether") * 3})
    with brownie.reverts("NFTBoxes: Minting too many boxes."):
        nftbox.buyManyBoxes(1, 6, {'from':accounts[0], "value": Wei("0.01 ether") * 6})
    nftbox.buyManyBoxes(1, 2, {'from':accounts[0], "value": Wei("0.01 ether") * 2})

    with brownie.reverts("NFTBoxes: Minting too many boxes."):
        nftbox.buyManyBoxes(1, 1, {'from':accounts[0], "value": Wei("0.01 ether")})


def test_box_out_of_range(nftbox, joy, minter, accounts):
    joy.setCaller(nftbox, True, {'from':minter})
    nftbox.setVendingMachine(joy, {'from': minter})
    nftbox.createBoxMould(1, 1, Wei('100 ether'), [], [], "This is a test box", "", "", "", "", {'from':minter})
    nftbox.setLockOnBox(1, False, {'from':minter})
    joy.createNFTMould("", "", "owl", accounts[2], "0x", "0x", 100, "title", "type", "detail", accounts[2], 2,{'from':minter})
    with brownie.reverts("NFTBoxes: Mould ID does not exist."):
        nftbox.buyManyBoxes(5, 1, {'from':accounts[0]})

def test_many_of_one(nftbox, minter, accounts):
    nftbox.createBoxMould(50, 50, Wei('0.01 ether'), [], [], "This is a test box", "", "", "", "", {'from':minter})
    nftbox.createBoxMould(20, 50, Wei('0.1 ether'), [], [], "This is a test box", "", "", "", "", {'from':minter})
    nftbox.setLockOnBox(1, False, {'from':minter})
    nftbox.setLockOnBox(2, False, {'from':minter})
    nftbox.buyManyBoxes(2, 5, {'from':accounts[0], "value": Wei("0.1 ether") * 5})
    supply = nftbox.totalSupply()
    for i in range(10):
        nftbox.buyManyBoxes(1, 1, {'from':accounts[0], "value": Wei("0.01 ether")})
        assert nftbox.ownerOf(2 * i + supply) == accounts[0]
        assert nftbox.boxes(2 * i + supply) == (1, i * 2 + 1)
        nftbox.buyManyBoxes(1, 1, {'from':accounts[1], "value": Wei("0.01 ether")})
        assert nftbox.ownerOf(2 * i + supply + 1) == accounts[1]
        assert nftbox.boxes(2 * i + 1 + supply) == (1, i * 2 + 1 + 1)

def test_many_at_once(nftbox, minter, accounts):
    nftbox.createBoxMould(30, 30, Wei('0.01 ether'), [], [], "This is a test box", "", "", "", "", {'from':minter})
    nftbox.createBoxMould(20, 20, Wei('0.1 ether'), [], [], "This is a test box", "", "", "", "", {'from':minter})
    nftbox.setLockOnBox(1, False, {'from':minter})
    nftbox.setLockOnBox(2, False, {'from':minter})
    nftbox.buyManyBoxes(2, 5, {'from':accounts[0], "value": Wei("0.1 ether") * 5})
    supply = nftbox.totalSupply()
    for i in range(10):
        nftbox.buyManyBoxes(1, 1, {'from':accounts[0], "value": Wei("0.01 ether")})
        assert nftbox.ownerOf(2 * i + supply) == accounts[0]
        assert nftbox.boxes(2 * i + supply) == (1, i * 2 + 1)
        nftbox.buyManyBoxes(1, 1, {'from':accounts[1], "value": Wei("0.01 ether")})
        assert nftbox.ownerOf(2 * i + supply + 1) == accounts[1]
        assert nftbox.boxes(2 * i + 1 + supply) == (1, i * 2 + 1 + 1)
    nftbox.buyManyBoxes(1, 5, {'from':accounts[0], "value": Wei("0.01 ether") * 5})
    with brownie.reverts("NFTBoxes: Wrong total price."):
        nftbox.buyManyBoxes(1, 5, {'from':accounts[0], "value": Wei("0.01 ether")})
    nftbox.buyManyBoxes(1, 5, {'from':accounts[0], "value": Wei("0.01 ether") * 5})
    with brownie.reverts("NFTBoxes: Minting too many boxes."):
        nftbox.buyManyBoxes(1, 5, {'from':accounts[0], "value": Wei("0.01 ether") * 5})
    with brownie.reverts("NFTBoxes: Minting too many boxes."):
        nftbox.buyManyBoxes(1, 1, {'from':accounts[0], "value": Wei("0.01 ether")})


def test_not_buyable_edition_over(nftbox, minter, accounts):
    nftbox.createBoxMould(5, 5, Wei('0.01 ether'), [], [], "This is a test box", "", "", "", "", {'from':minter})
    nftbox.setLockOnBox(1, False, {'from':minter})
    nftbox.buyManyBoxes(1, 5, {'from':accounts[0], "value": Wei("0.01 ether") * 5})
    with brownie.reverts("NFTBoxes: Minting too many boxes."):
        nftbox.buyManyBoxes(1, 1, {'from':accounts[0], "value": Wei("0.01 ether")})

def test_wrong_price(nftbox, minter, accounts):
    nftbox.createBoxMould(50, 50, Wei('0.01 ether'), [], [], "This is a test box", "", "", "", "", {'from':minter})
    nftbox.setLockOnBox(1, False, {'from':minter})
    for j in range(5):
        nftbox.buyManyBoxes(1, 1, {'from':accounts[0], "value": Wei("0.01 ether")})
    with brownie.reverts("NFTBoxes: Wrong total price."):
        nftbox.buyManyBoxes(1, 1, {'from':accounts[0], "value": Wei("1 ether")})

# def t1est_distribution_with_machine_one(nftbox, joy, me, minter, accounts):
#     joy.setCaller(nftbox, True, {'from':minter})
#     nftbox.setVendingMachine(joy, {'from': minter})
#     nftbox.createBoxMould(1, Wei('0.01 ether'), [], [], "This is a test box", "", "", "", "", {'from':minter})
#     for i in range(1, 5):
#         print(f'minting id {i}')
#         joy.createNFTMould("", "", "owl", me, "0x", "0x", 100, "title", "type", "detail", me, 2,{'from':minter})
#     nftbox.buyManyBoxes(1, 1, {'from':accounts[0], "value": Wei("0.01 ether")})
#     nftbox.distribute(1, 1,{'from':minter})
#     assert nftbox.balanceOf(accounts[0]) == 1
#     assert joy.balanceOf(accounts[0]) == 4

# def t1est_distribution_with_machine(nftbox, joy, minter, accounts):
#     joy.setCaller(nftbox, True, {'from':minter})
#     nftbox.setVendingMachine(joy, {'from': minter})
#     nftbox.createBoxMould(20, Wei('0.01 ether'), [1, 2, 3, 4, 5, 6, 7, 8, 9, 10], [], [], "This is a test box", "", "", "", "", {'from':minter})
#     for i in range(1, 11):
#         joy.createNFTMould("", "", "owl", me, "0x", "0x", 100, "title", "type", "detail", me, 2,{'from':minter})
#     for j in range(10):
#         for k in range(2):
#             nftbox.buyBox(1, {'from':accounts[j], "value": Wei("0.01 ether")})
#     for i in range(10):
#         nftbox.distribute(1, 2,{'from':minter})
#     for i in range(10):
#         assert joy.balanceOf(accounts[i]) == 20

# def t1est_distribution_with_machine2(nftbox, joy, minter, accounts):
#     joy.setCaller(nftbox, True, {'from':minter})
#     nftbox.setVendingMachine(joy, {'from': minter})
#     nftbox.createBoxMould(20, Wei('0.01 ether'), [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20], [], [], "This is a test box", "", "", "", "", {'from':minter})
#     for i in range(1, 21):
#         joy.createNFTMould("c0ffee", "someType", "over 9000", "toy", "fun", 100, True, 0, 0, {'from':minter})
#     for j in range(10):
#         for k in range(2):
#             print(f'{j}.{k} buy')
#             nftbox.buyBox(1, {'from':accounts[j], "value": Wei("0.01 ether")})
#     for i in range(10):
#         print(f'distribute {i}')
#         nftbox.distribute(1, 2,{'from':minter})
#     for i in range(10):
#         assert joy.balanceOf(accounts[i]) == 40


def test_bad_shares(nftbox, joy, minter, accounts, me, me2, me3, big):
    joy.setCaller(nftbox, True, {'from':minter})
    nftbox.setVendingMachine(joy, {'from': minter})
    nftbox.createBoxMould(1, 1, Wei('100 ether'), [], [], "This is a test box", "", "", "", "", {'from':minter})
    joy.createNFTMould("", "", "owl", me, "0x", "0x", 100, "title", "type", "detail", me, 2,{'from':minter})

    nftbox.addTeamMember(me, {'from':minter})
    nftbox.setTeamShare(me, 600, {'from':minter})

    nftbox.addTeamMember(me2, {'from':minter})
    nftbox.setTeamShare(me2, 400, {'from':minter})

    nftbox.addTeamMember(me3, {'from':minter})
    nftbox.setTeamShare(me3, 10, {'from':minter})
    nftbox.setLockOnBox(1, False, {'from':minter})
    nftbox.buyManyBoxes(1, 1, {'from':accounts[0], 'value':  Wei('100 ether')})
    preme = me.balance()
    preme2 = me2.balance()
    preme3 = me3.balance()
    with brownie.reverts("NFTBoxes: shares do not add up to 100%."):
        nftbox.distributeShares(1,{'from':minter})
    nftbox.removeTeamMember(me3, {'from':minter})
    nftbox.distributeShares(1,{'from':minter})
    assert me.balance() == preme + Wei('100 ether') * 600 / 1000
    assert me2.balance() == preme2 + Wei('100 ether') * 400 / 1000

def test_shares(nftbox, joy, minter, accounts, me, me2, me3, big):
    joy.setCaller(nftbox, True, {'from':minter})
    nftbox.setVendingMachine(joy, {'from': minter})
    nftbox.createBoxMould(1, 1, Wei('100 ether'), [accounts[1], accounts[2], accounts[3]], [240, 260, 250], "This is a test box", "", "", "", "", {'from':minter})
    nftbox.setLockOnBox(1, False, {'from':minter})
    joy.createNFTMould("", "", "owl", me, "0x", "0x", 100, "title", "type", "detail", me, 2,{'from':minter})

    nftbox.addTeamMember(me, {'from':minter})
    nftbox.setTeamShare(me, 100, {'from':minter})

    nftbox.addTeamMember(me2, {'from':minter})
    nftbox.setTeamShare(me2, 76, {'from':minter})

    nftbox.addTeamMember(me3, {'from':minter})
    nftbox.setTeamShare(me3, 74, {'from':minter})

    nftbox.buyManyBoxes(1, 1, {'from':accounts[0], 'value':  Wei('100 ether')})

    preme = me.balance()
    preme2 = me2.balance()
    preme3 = me3.balance()
    preacc1 = accounts[1].balance()
    preacc2 = accounts[2].balance()
    preacc3 = accounts[3].balance()
    nftbox.distributeShares(1,{'from':minter})
    assert me.balance() == preme + Wei('100 ether') * 100 / 1000
    assert me2.balance() == preme2 + Wei('100 ether') * 76 / 1000
    assert me3.balance() == preme3 + Wei('100 ether') * 74 / 1000
    assert accounts[1].balance() == preacc1 + Wei('100 ether') * 240 / 1000
    assert accounts[2].balance() == preacc2 + Wei('100 ether') * 260 / 1000
    assert accounts[3].balance() == preacc3 + Wei('100 ether') * 250 / 1000



# def f():
# minter = accounts.at("0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2", force=True)
# box = NFTBoxes.deploy({'from':minter})
# box.createBoxMould(50, Wei('0.1 ether'), "This is a test box", "", "", "", "", {'from':minter})
# box.createBoxMould(25, Wei('1 ether'), "This is a second test box", "", "", "", "", {'from':minter})
# box.buyBox(0, {'from':minter, "value": Wei("0.1 ether")})
