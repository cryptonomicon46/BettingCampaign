//SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "hardhat/console.sol";
interface ICampaign {

    /**
     * @dev enum that selects the Motorcyle race premier league class of the campaign
     */
    enum PremierLeague {ZERO,MotoGp, Moto2, WSBK}

    /**
     * @dev enum defines the stage of any given league, Accepting Bets/Closed/RevealWinner
     */
    enum Stages {ZERO, AcceptingBets, Closed, RevealWinner}


    /**
     * 
     */
    struct CampaignDetails { 
        uint256 raceNum;
        uint256 raceDate;
        Stages stage;
        PremierLeague league;
    }
    /**
     * @notice createCampaign only Owner of this contract can launch a  MotoGp=1/Moto2=2/WSBK=3 Betting campaign
     * @param league selects the league of motorcycle racing, which could be MotoGp=1/Moto2=2/WSBK=3 
     * @param raceNum is the race round for the selected Premier League 
     * @param raceDate is the race Date 
     * @return bool true if the campaign is created 
     * 
     */
    function createCampaign(PremierLeague league, uint256 raceNum,  uint256 raceDate) external returns (bool);

    function getCampaignInfo(uint256 _campaignId) external returns (CampaignDetails memory);

}

contract BettingCampaign is Ownable, ICampaign {
    using SafeMath for uint256;
    mapping(uint256 => CampaignDetails) private campaign_info;
    uint256 private _totalCampaigns=1;
  


/**
 * event CampaignCreated emitted when a new campaign is created by the owner 
 */
    event CampaignCreated(PremierLeague, uint256 raceNum, uint256 raceDate);
    constructor () {

    }

    /**
     * @notice createCampaign only Owner of this contract can launch a  MotoGp=1/Moto2=2/WSBK=3 Betting campaign
     * @param league selects the league of motorcycle racing, which could be MotoGp=1/Moto2=2/WSBK=3 
     * @param raceNum is the race round for the selected Premier League 
     * @param raceDate is the race Date 
     * @return bool true if the campaign is created 
     */
function createCampaign(PremierLeague league, uint256 raceNum,  uint256 raceDate) external virtual override onlyOwner returns (bool) {
    // require(league >0 && league<=3,"BettingCampaign: Invalid league ID MotoGp=1/Moto2=2/WSBK=3");
    campaign_info[_totalCampaigns]= CampaignDetails(raceNum,raceDate,Stages.AcceptingBets, league);
    console.log(uint(Stages.AcceptingBets));
    _totalCampaigns = _totalCampaigns.add(1);
    emit CampaignCreated(league, raceNum, raceDate);
}



    /**
     * @notice getCampaignInfo Gets the campaign info for a specified campaign id  
     * @param _campaignId the ID of the campaign 
     * @return CampaignDetails returns the campaign details struct that has the raceNum, raceDate and campaign Stage (acceptingBets, Stopped, RevealWinner)
     */
    function getCampaignInfo(uint256 _campaignId) external view virtual override returns (CampaignDetails memory){
        require(_campaignId<= _totalCampaigns,"BettingCampaign: Invalid campaign ID number");
        // console.log("Stage:", campaign_info[_campaignId].stage);
        return campaign_info[_campaignId];

    }


}