local Jp = _G.Jp
local Bidding = {}
Jp.Bidding = Bidding

local AuctionInProgress = false
local BiddingRoundRoster = {}
local FullDkp = 80

local function clearBiddingRoster()
    for player, _ in pairs(BiddingRoundRoster) do
        BiddingRoundRoster[player] = nil
    end
end

function Bidding:stopBiddingRound()
    clearBiddingRoster()
    AuctionInProgress = false
end

function Bidding:getBidders()
    return BiddingRoundRoster
end

function Bidding:auctionInProgress()
    return AuctionInProgress
end

function Bidding:setAuctionInProgress(boolean)
    AuctionInProgress = boolean
end

function Bidding:addBidder(bidder, amount)
    if not amount then
        BiddingRoundRoster[bidder] = FULL_DKP
    else
        BiddingRoundRoster[bidder] = amount
    end
end

function Bidding:getBid(player)
    if (BiddingRoundRoster[player] == FULL_DKP) then
        return FullDkp
    end
    return BiddingRoundRoster[player]
end

function Bidding:setBidInPlayerManagement(player)
    local playerBid = Bidding:getBid(player)
    if (playerBid ~= nil) then
        getglobal(PLAYER_MANAGEMENT .. "Value"):SetText(playerBid)
    else
        getglobal(PLAYER_MANAGEMENT .. "Value"):SetText("")
    end
end