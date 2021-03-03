import pytest
import brownie
from brownie import Wei

def test_correct_voucher_count(nftbox, voucher, minter, accounts, chain):
    voucher.setCaller(nftbox, True, {'from':minter})
    nftbox.setBoxVoucher(voucher, {'from':minter})
    nftbox.createBoxMould(50, 50, 26, Wei('0.1 ether'), [], [], "This is a test box", "", "", "", "", {'from':minter})
    assert voucher.totalSupply(1) == 26

def test_buy_with_voucher(nftbox, voucher, minter, accounts, chain):
    voucher.setCaller(nftbox, True, {'from':minter})
    nftbox.setBoxVoucher(voucher, {'from':minter})
    nftbox.createBoxMould(50, 50, 26, Wei('0.1 ether'), [], [], "This is a test box", "", "", "", "", {'from':minter})
    for i in range(5):
        voucher.safeTransferFrom(minter, accounts[i], 1, 2, "", {'from':minter})
    with brownie.reverts('NFTBoxes: Box is locked'):
        nftbox.buyBoxesWithVouchers(1, 2, {'from':accounts[0]})
    nftbox.setLockOnBox(1, False, {'from':minter})
    with brownie.reverts('ERC1155: burn amount exceeds balance'):
        nftbox.buyBoxesWithVouchers(1, 2, {'from':accounts[5], 'value':Wei('0.1 ether') * 2})
    for i in range(5):
        nftbox.buyBoxesWithVouchers(1, 2, {'from':accounts[i], 'value':Wei('0.1 ether') * 2})
        assert nftbox.balanceOf(accounts[i]) == 2
    with brownie.reverts('ERC1155: burn amount exceeds balance'):
        nftbox.buyBoxesWithVouchers(1, 2, {'from':accounts[4], 'value':Wei('0.1 ether') * 2})

def test_buy_with_voucher_then_normal(nftbox, voucher, minter, accounts, chain):
    voucher.setCaller(nftbox, True, {'from':minter})
    nftbox.setBoxVoucher(voucher, {'from':minter})
    nftbox.createBoxMould(50, 50, 26, Wei('0.1 ether'), [], [], "This is a test box", "", "", "", "", {'from':minter})
    for i in range(1, 6):
        voucher.safeTransferFrom(minter, accounts[i], 1, 2, "", {'from':minter})
    with brownie.reverts('NFTBoxes: Box is locked'):
        nftbox.buyBoxesWithVouchers(1, 2, {'from':accounts[0]})
    nftbox.setLockOnBox(1, False, {'from':minter})
    with brownie.reverts('ERC1155: burn amount exceeds balance'):
        nftbox.buyBoxesWithVouchers(1, 2, {'from':accounts[6], 'value':Wei('0.1 ether') * 2})
    for i in range(1, 6):
        nftbox.buyBoxesWithVouchers(1, 2, {'from':accounts[i], 'value':Wei('0.1 ether') * 2})
        assert nftbox.balanceOf(accounts[i]) == 2
    with brownie.reverts('ERC1155: burn amount exceeds balance'):
        nftbox.buyBoxesWithVouchers(1, 2, {'from':accounts[1], 'value':Wei('0.1 ether') * 2})
    nftbox.distributeReservedBoxes(1, 20, {'from':minter})
    chain.sleep(901)
    for i in range(4):
        nftbox.buyManyBoxes(1, 10, {'from':accounts[i], 'value':Wei('0.1 ether') * 10})
    with brownie.reverts('NFTBoxes: Too many boxes'):
        nftbox.buyManyBoxes(1, 1, {'from':accounts[9], 'value':Wei('0.1 ether')})
    assert nftbox.totalSupply() == 50

def test_voucher_reservations_then_normal(nftbox, voucher, minter, accounts, chain):
    voucher.setCaller(nftbox, True, {'from':minter})
    nftbox.setBoxVoucher(voucher, {'from':minter})
    nftbox.createBoxMould(50, 50, 26, Wei('0.1 ether'), [], [], "This is a test box", "", "", "", "", {'from':minter})
    for i in range(1, 6):
        voucher.safeTransferFrom(minter, accounts[i], 1, 2, "", {'from':minter})
        with brownie.reverts('NFTBoxes: !price'):
            nftbox.reserveBoxes(1, 2, {'from':accounts[i]})
        nftbox.reserveBoxes(1, 2, {'from':accounts[i], 'value': Wei('0.1 ether') * 2 * 21 // 20})
    voucher.safeTransferFrom(minter, accounts[7], 1, 2, "", {'from':minter})
    nftbox.setLockOnBox(1, False, {'from':minter})
    nftbox.buyBoxesWithVouchers(1, 10, {'from':accounts[0], 'value':Wei('0.1 ether') * 10})
    with brownie.reverts('NFTBoxes: Buy window not open'):
        nftbox.buyManyBoxes(1, 40, {'from':accounts[9], 'value':Wei('0.1 ether') * 40})
    nftbox.distributeReservedBoxes(1, 20, {'from':minter})
    with brownie.reverts('NFTBoxes: Cannot reserve anymore'):
            nftbox.reserveBoxes(1, 2, {'from':accounts[i], 'value': Wei('0.1 ether') * 2 * 21 // 20})
    assert nftbox.totalSupply() == 20
    with brownie.reverts('NFTBoxes: Buy window not open'):
        nftbox.buyManyBoxes(1, 40, {'from':accounts[9], 'value':Wei('0.1 ether') * 40})
    chain.sleep(901)
    nftbox.buyManyBoxes(1, 30, {'from':accounts[9], 'value':Wei('0.1 ether') * 30})
    with brownie.reverts('NFTBoxes: Too many boxes'):
        nftbox.buyManyBoxes(1, 1, {'from':accounts[9], 'value':Wei('0.1 ether')})
    assert nftbox.totalSupply() == 50

def test_reservation_queue(nftbox, voucher, minter, accounts, chain):
    voucher.setCaller(nftbox, True, {'from':minter})
    nftbox.setBoxVoucher(voucher, {'from':minter})
    nftbox.createBoxMould(50, 50, 20, Wei('0.1 ether'), [], [], "This is a test box", "", "", "", "", {'from':minter})
    for i in range(1, 6):
        voucher.safeTransferFrom(minter, accounts[i], 1, 4, "", {'from':minter})
        with brownie.reverts('NFTBoxes: !price'):
            nftbox.reserveBoxes(1, 4, {'from':accounts[i]})
        nftbox.reserveBoxes(1, 4, {'from':accounts[i], 'value': Wei('0.1 ether') * 4 * 21 // 20})
    nftbox.setLockOnBox(1, False, {'from':minter})
    with brownie.reverts('ERC1155: burn amount exceeds balance'):
        nftbox.buyBoxesWithVouchers(1, 2, {'from':accounts[0], 'value':Wei('0.1 ether') * 2})
    nftbox.distributeReservedBoxes(1, 10, {'from':minter})
    assert nftbox.getReservationCount(1) == 10
    assert nftbox.voucherValidityInterval(1) == 0
    nftbox.distributeReservedBoxes(1, 10, {'from':minter})
    assert nftbox.getReservationCount(1) == 0
    assert nftbox.voucherValidityInterval(1) != 0