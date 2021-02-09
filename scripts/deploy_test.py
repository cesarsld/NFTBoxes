from brownie import NFTBoxesBox, NFTBoxesNFT, accounts, chain, interface, Wei, web3
from time import sleep

def main():
    user = accounts.load('moist')
    box = NFTBoxesBox.deploy({'from':user}, publish_source=False)

    box.setCaller(user, True, {'from':user})
    box.setCaller('0x63a9dbCe75413036B2B778E670aaBd4493aAF9F3', True, {'from':user})

    artists = [
        '0xca2b6756486E598580792CC5C0A27F13D57E630f',
        '0x576a655161B5502dCf40602BE1f3519A89b71658',
        '0x707611854951352F9Fda16D6b5162b299112Dfba',
        '0xa8E376248FB85dD9680FdbeEcC3ec72e20C37CAc',
        '0x7535Da202d79cA57299918c60C218f9b779AA14c',
        '0x84300dCc7ca9Cf447e886fA17C11fa22557d1AF0',
        '0x7485ac6d8534691993348D51ab0F131a19FfF763'
    ]
    artist_shares = [200,20,20,20,40,20,20]


    box.createBoxMould(500, 5, '0.5 ether', artists, artist_shares, 'Genesis Box',
        'Main', 'Innovators',
        'QmNSWXCtpk8YEZWUcp5X9yFYXyRJbCbm5FCRJvZyvK29sy',
        'bSFksvslqiyEGj7ABWOUkx2wJZkkrSca5Puts3CTFYc', {'from': user})

    box.transferOwnership('0xAd67593b01385792CA671ABe6d975801c2e86D22', {'from':user})

