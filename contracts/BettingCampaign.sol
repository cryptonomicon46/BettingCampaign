//SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
interface ICampaign {

    /**
     * @dev enum that selects the Motorcyle race premier league class of the campaign
     */
    enum PremierLeague {Ignore,MotoGp, Moto2, WSBK}

    /**
     * @dev enum defines the stage of any given league, Accepting Bets/Closed/RevealWinner
     */
    enum Stages {AcceptingBets, Closed, RevealWinner}


    /**
     * 
     */
    struct CampaignDetails { 
        uint256 raceNum;
        uint256 raceDate;
        Stages stage;
    }
    /**
     * createCampaign creates a new MotoGp=1/Moto2=2/WSBK=3 campaign 
     * 
     */
    function createCampaign(PremierLeague _league, uint256 raceNum,  uint256 raceDate ) external returns (bool);

}

contract BettingCampaign is Ownable, ICampaign {
    using SafeMath for uint256;
    mapping(uint256 => CampaignDetails) private campaign_info;
    uint256 private _totalCampaigns;


/**
 * event CampaignCreated emitted when a new campaign is created by the owner 
 */
    event CampaignCreated(PremierLeague, uint256 raceNum, uint256 raceDate);
    constructor () {

    }

    /**
     * @notice createCampaign only Owner of this contract can launch a  MotoGp=1/Moto2=2/WSBK=3 Betting campaign
     * @param _league selects the league of motorcycle racing, which could be MotoGp=1/Moto2=2/WSBK=3 
     * @param raceNum is the race round for the selected Premier League 
     * @param raceDate is the race Date 
     * @return bool true if the campaign is created 
     */
function createCampaign(PremierLeague _league, uint256 raceNum,  uint256 raceDate ) external virtual override onlyOwner returns (bool) {
    campaign_info[_totalCampaigns]= CampaignDetails(raceNum,raceDate,Stages.AcceptingBets);
    _totalCampaigns = _totalCampaigns.add(1);
    emit CampaignCreated(_league, raceNum, raceDate);
}


// function getCampaignInfo(uint256 _campaignId) {}

}