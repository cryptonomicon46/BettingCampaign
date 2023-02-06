//SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

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
        uint256 raceWinner;
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



    /**
     * @notice getCampaignInfo Gets the campaign info for a specified campaign id  
     * @param _campaignId the ID of the campaign 
     * @return CampaignDetails returns the campaign details struct that has the raceNum, raceDate and campaign Stage (acceptingBets, Stopped, RevealWinner)
     */
    function getCampaignInfo(uint256 _campaignId) external returns (CampaignDetails memory);


    /**
     * AcceptBets is the user interface to accept bets for a campaign
     * @param _campaignId is the campaignID created by the owner for a particular race either in MotoGP/Moto2 or WSBK.
     */
    function AcceptBets(uint256 _campaignId) external payable;

    function RaceWinnerSet(uint256 _campaignId,uint256 racerWhoWon) external returns (bool) ;

     function WithdrawWinnings(uint256 _campaignId) external payable;

}

contract BettingCampaign is Context, Ownable, ReentrancyGuard, ICampaign {
    using SafeMath for uint256;
    uint256 private _totalCampaigns=1;
    uint256 public ENTRY_FEE = 1 ether;
    mapping(uint256 => CampaignDetails) private campaign_info;
    mapping (address=> uint256) public userBalance;
    mapping (uint256=> uint256) public campaginBalance;
    mapping(uint256 => address) public campaignWinner;



/**
 *  event CampaignCreated is emitted when a new campaign is created by the owner 
 */
    event CampaignCreated( PremierLeague indexed , uint256 indexed raceNum, uint256 indexed raceDate);

/**
 *  event EntryFeeUpdated is emitted when the entry fee is updated by the owner 
 */
    event EntryFeeUpdated(uint256 indexed NEW_ENTRY_FEE);

/**
 * event AcceptedBet is emitted when the campaign accepts the user's bet
 */

    event AcceptedBet(uint256 indexed _campaignId,address indexed _msgSender);

/**
 * event RaceWinner emitted when the owner of this contract sets the winner of the race after the race has ended 
 */
event RaceWinner(uint256 indexed _campaignId, uint256 racerWhoWon);


/**
 * event CampaignStageChanged emitted when the campaign stage is changed by the owner of the contract
 */
event CampaignStageChanged(uint256 _campaignId, Stages _stage);
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
    campaign_info[_totalCampaigns]= CampaignDetails(raceNum,raceDate,Stages.AcceptingBets, league,0);
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
        require(_campaignId!=0 && _campaignId<= _totalCampaigns,"BettingCampaign: Invalid campaign ID number");
        // console.log("Stage:", campaign_info[_campaignId].stage);
        return campaign_info[_campaignId];

    }

    /**
     * @dev _setStage is an internal function that returns the currents 
     * stage of the League (AcceptingBets/Stopped/RevealWinner)
     */
    function _setStage(uint256 _campaignId) private returns (Stages ) {
        if (block.timestamp <= campaign_info[_campaignId].raceDate- 4 days ) 
            {return campaign_info[_campaignId].stage = Stages.AcceptingBets; }
        else 
            {return campaign_info[_campaignId].stage  = Stages.Closed; }
        }

    /**
     * @dev _stageConfirmation is an internal function that confirms the input stage of a the campaign
     */
    function _stageConfirmation(uint256 _campaignId, Stages _stage) private returns (bool ) {
        _setStage(_campaignId);
        return campaign_info[_campaignId].stage == _stage;

    }


    /**
     * changeCampaignStage to manually change the campaign stage only by the owner of the contract 
     * @param _campaignId the ID of the campaign 
     * @param _stage change the campaign stage to this (AcceptingBids/Stopped/RevealWinner)
     */
    function changeCampaignStage(uint256 _campaignId, Stages _stage) external onlyOwner {
        require(_campaignId!=0 && _campaignId<= _totalCampaigns,"BettingCampaign: Invalid campaign ID number");
        campaign_info[_campaignId].stage  = _stage;
        emit CampaignStageChanged(_campaignId, _stage);

    }

/**
 * @notice AcceptBets is the user interface to accept bets for a campaign
 * @param _campaignId is the campaignID created by the owner for a particular race either in MotoGP/Moto2 or WSBK.
 * @dev emits the AcceptedBet event once the bet for the campaign is accepted
 */

 function AcceptBets(uint256 _campaignId) external payable virtual override  {
        require(_stageConfirmation(_campaignId,Stages.AcceptingBets),
        "BettingCampaign: Currently not accepting bets for this campaign!");
        
        require(_campaignId!=0 && _campaignId<= _totalCampaigns,"BettingCampaign: Invalid campaign ID number");
        require(msg.value== ENTRY_FEE, "BettingCampaign: Entry fee criteria criteria not met!");
        require(block.timestamp < campaign_info[_campaignId].raceDate- 4 days,
        "BettingCampain: Bets accepted only under the Wednesday of the raceweek!");

        userBalance[_msgSender()] = userBalance[_msgSender()].add(msg.value);
        campaginBalance[_campaignId] = campaginBalance[_campaignId].add(msg.value);
        emit AcceptedBet(_campaignId,_msgSender());


 }


 /**
 * @dev RaceWinnerSet is called by the owner of the contract to set the racer who won a certain campaign 
 * @param _campaignId is the campaignID created for a certain race of MotoGP/Moto2 or WSBK.
 * @param racerWhoWon is the racer who won the race on Sunda for the leage
 * @return bool returns true if the operation succeeds.
 */

    function RaceWinnerSet(uint256 _campaignId,uint256 racerWhoWon) external onlyOwner virtual override returns (bool){
        require(_stageConfirmation(_campaignId,Stages.Closed),
        "BettingCampaign: This campaign hasn't yet closed!");
        campaign_info[_campaignId].raceWinner = racerWhoWon;
        emit RaceWinner(_campaignId,racerWhoWon);
        return true;
        
    }

    function revealWinner(uint256 _campaignId) external onlyOwner returns (address,uint256) {
      require(_stageConfirmation(_campaignId,Stages.Closed),
        "BettingCampaign: This campaign hasn't yet closed!");


    }


    function WithdrawWinnings(uint256 _campaignId) external payable virtual override nonReentrant {

        uint256 c_Bal =  campaginBalance[_campaignId];
         campaginBalance[_campaignId] = 0;
         (bool success, ) = payable(campaignWinner[_campaignId]).call{value: c_Bal}("");
         require(success, "BettingCampaign: Payout to the winner of the campaign failed!");

    }


    function updateEntryFee(uint256 NEW_ENTRY_FEE) external onlyOwner {
        ENTRY_FEE = NEW_ENTRY_FEE;
        emit EntryFeeUpdated(NEW_ENTRY_FEE); 
    }

}