import pytest


@pytest.fixture(scope="function", autouse=True)
def shared_setup(fn_isolation):
    pass


@pytest.fixture()
def minter(accounts):
    return accounts[0]
    # return accounts.at("0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2", force=True)

@pytest.fixture()
def me(accounts):
    return accounts.at("0xf521Bb7437bEc77b0B15286dC3f49A87b9946773", force=True)

@pytest.fixture()
def me2(accounts):
    return accounts.at("0xf521Bb7437bEc77b0B15286dC3f49A87b9946774", force=True)

@pytest.fixture()
def me3(accounts):
    return accounts.at("0xf521Bb7437bEc77b0B15286dC3f49A87b9946775", force=True)

@pytest.fixture()
def big(accounts):
    return accounts.at("0x742d35cc6634c0532925a3b844bc454e4438f44e", force=True)

@pytest.fixture()
def nftbox(NFTBoxesBox, minter, accounts):
    return NFTBoxesBox.deploy({'from':minter})

@pytest.fixture()
def voucher(BoxVoucher, minter, accounts):
    return BoxVoucher.deploy({'from':minter})

@pytest.fixture()
def joy(NFTBoxesNFT, minter, accounts):
    return NFTBoxesNFT.deploy({'from':minter})

@pytest.fixture()
def testnft(TestNFT, minter):
    return TestNFT.deploy({'from':minter})
