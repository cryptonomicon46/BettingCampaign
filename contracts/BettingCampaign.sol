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
    enum Stages {ZERO, AcceptingBets, Closed, RevealWinner,Payout, Issue}


    /**
     * 
     */
    struct CampaignDetails { 
        uint256 raceNum;
        uint256 raceDate;
        Stages stage;
        PremierLeague league;
        uint256 raceWinner;
        uint256 campaignBal;
        address campaignWinner;
    }

        struct Bidder {
        uint userBetVal;
        uint userBetTimeStamp;
        uint userRacerPick;
        address userAddress;
  
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
     * @notice AcceptBets is the user interface to accept bets for a campaign
     * @param _campaignId is the campaignID created by the owner for a particular race either in MotoGP/Moto2 or WSBK.
     * @param Racer the racer to be bet on
     *  @dev emits the AcceptedBet event once the bet for the campaign is accepted
     */

    function AcceptBets(uint256 _campaignId,uint256 Racer) external payable;


    /**
     * @dev OnwerSetsRaceWinner is called by the owner of the contract to set the racer who won a certain campaign 
     * @param _campaignId is the campaignID created for a certain race of MotoGP/Moto2 or WSBK.
     * @param racerWhoWon is the racer who won the race on Sunda for the leage
     * @return bool returns true if the operation succeeds.
     */
    function OnwerSetsRaceWinner(uint256 _campaignId,uint256 racerWhoWon) external returns (bool) ;


     function WithdrawWinnings(uint256 _campaignId) external payable;


}

contract BettingCampaign is Context, Ownable, ReentrancyGuard, ICampaign {
    using SafeMath for uint256;
    uint256 private _totalCampaigns=1;
    uint256 public ENTRY_FEE = 0.5 ether;
    uint256 private _platformFees = 5;   //5%
    address payable public devAddress; //payable?


    mapping(uint256 => CampaignDetails) public campaign_info;

    //  mapping (uint256=> uint256) public campaginBalance;
    // mapping(uint256 => address) public campaignWinner;

    mapping(uint256 =>mapping(address=>bool))public hasBet;

     Bidder[] private bidder;
    mapping(uint256 => mapping(uint256 => Bidder[]))public bidders; //Per racer Number

    mapping(address => mapping(uint256 => Bidder)) public userInfo; //UserInfo per campaign


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

    event AcceptedBet(uint256 indexed _campaignId,address indexed _msgSender, uint256 indexed betAmount);

/**
 * event RaceWinner emitted when the owner of this contract sets the winner and computes the winning bet
 */
event RaceWinner(uint256 indexed _campaignId, address indexed  winningBetAddr, uint256 indexed winnerProceeds);
    
    
    /**
     * Developer address set by the owner of this contract
     */
    event  DevAddressUpdated(address devAddress_);


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
    campaign_info[_totalCampaigns]= CampaignDetails(raceNum,raceDate,Stages.AcceptingBets, league,0,0,address(0));
    // console.log( campaign_info[_totalCampaigns].stage);
    Stages test = campaign_info[_totalCampaigns].stage;
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
        return  campaign_info[_campaignId];

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

 function AcceptBets(uint256 _campaignId,uint256 Racer) external payable virtual override  {
        require(_stageConfirmation(_campaignId,Stages.AcceptingBets),
        "BettingCampaign: Currently not accepting bets for this campaign!");
        
        require(_campaignId!=0 && _campaignId<= _totalCampaigns,"BettingCampaign: Invalid campaign ID number");
        require(msg.value>= ENTRY_FEE, "BettingCampaign: Entry fee criteria criteria not met!");
        require(block.timestamp < campaign_info[_campaignId].raceDate- 4 days,
        "BettingCampain: Bets accepted only under the Wednesday of the raceweek!");
        require(!hasBet[_campaignId][_msgSender()],"BettingCampaign: You cannot bet on the same campaign again!");
    

        bidders[_campaignId][Racer].push (Bidder({
                                        userBetVal: msg.value,
                                        userBetTimeStamp:block.timestamp,
                                        userRacerPick: Racer,
                                        userAddress: _msgSender()
                                        }));
        hasBet[_campaignId][_msgSender()] = true;
        

        campaign_info[_campaignId].campaignBal = campaign_info[_campaignId].campaignBal.add(msg.value);
        
        emit AcceptedBet(_campaignId,_msgSender(), msg.value);


 }


 /**
 * @dev OnwerSetsRaceWinner is called by the owner of the contract to set the racer who won a certain campaign 
 * @param _campaignId is the campaignID created for a certain race of MotoGP/Moto2 or WSBK.
 * @param racerWhoWon is the racer who won the race on Sunda for the leage
 * @return bool returns true if the operation succeeds.
 */

    function OnwerSetsRaceWinner(uint256 _campaignId,uint256 racerWhoWon) external onlyOwner virtual override returns (bool){
        require(campaign_info[_campaignId].stage==Stages.Closed, "BettingCampaign: This campaign hasn't yet closed!");
        address _cWinner;
        uint256 _proceeds;
        campaign_info[_campaignId].raceWinner = racerWhoWon;

        campaign_info[_campaignId].stage = Stages.RevealWinner;

        if(_findTheCampaignWinner(_campaignId,racerWhoWon)) {
            campaign_info[_campaignId].stage = Stages.Payout;}
        else {
            campaign_info[_campaignId].stage = Stages.Issue;

        }
        emit RaceWinner(_campaignId,campaign_info[_campaignId].campaignWinner,campaign_info[_campaignId].campaignBal);
        return true;
        
    }

/**
 * @notice findTheCampaignWinner is an internal function which will compute the winner for the specified betting campaign 
 * @dev winners are determined by the bettinng amount/campaign, and if the bet amounts are the same, then by the timestamp
 */
    function _findTheCampaignWinner(uint256 _campaignId,uint256 racerWhoWon) private returns (bool) {
      require(campaign_info[_campaignId].stage==Stages.RevealWinner,
        "BettingCampaign: Race winner hasn't yet been set for this campaign");
        address _campaignWinner;
        uint256 _winningBet;
        uint256 _timeStamp;

        //Conditions,Sorted by the amount of money bet, and if equal, then use the timestamp to determine the winner
        Bidder[] memory WinnersArray= bidders[_campaignId][racerWhoWon];

                _winningBet = WinnersArray[0].userBetVal;
                _campaignWinner = WinnersArray[0].userAddress;
                _timeStamp = WinnersArray[0].userBetTimeStamp;

                // console.log("Number of ppl who bet on the Race winner:", WinnersArray.length);
                // console.log(_winningBet,_campaignWinner,_timeStamp, campaign_info[_campaignId].campaignBal);

            for (uint256 i=1; i< WinnersArray.length; i++) {
                // console.log(WinnersArray[i].userBetVal,
                // WinnersArray[i].userAddress, WinnersArray[i].userBetTimeStamp, campaign_info[_campaignId].campaignBal);

                if(WinnersArray[i].userBetVal> _winningBet) {
                _winningBet = WinnersArray[i].userBetVal;
                _campaignWinner = WinnersArray[i].userAddress;
                _timeStamp = WinnersArray[i].userBetTimeStamp;


                }
                else if(WinnersArray[i].userBetVal == _winningBet && WinnersArray[i].userBetTimeStamp< _timeStamp ) {
               _winningBet = WinnersArray[i].userBetVal;
                _campaignWinner = WinnersArray[i].userAddress;
                _timeStamp = WinnersArray[i].userBetTimeStamp;
                }
            }

            // campaign_info[_campaignId].campaignWinner = _campaignWinner;
        // console.log("\nWinningBet\n");
        // console.log(_winningBet,_campaignWinner,_timeStamp, campaign_info[_campaignId].campaignBal);
         campaign_info[_campaignId].campaignWinner= _campaignWinner;
         return true;
    

    }

/**
 * @notice WithdrawWinnings uses the Checks/Effects/Interactions pattern with 
 * Reentrancy guard to allow the bet winner to withdraw the campaign funds
 *  @param _campaignId is the campaignID created for a certain race of MotoGP/Moto2 or WSBK.
 */
    function WithdrawWinnings(uint256 _campaignId) external payable virtual override nonReentrant {
      require(_stageConfirmation(_campaignId,Stages.Payout),
        "BettingCampaign: Campaign isn't yet in the payout stage!");
        uint256 c_Bal =  campaign_info[_campaignId].campaignBal;
         campaign_info[_campaignId].campaignBal = 0;
         require(campaign_info[_campaignId].campaignWinner!= address(0),"BettingContract: Invalid payout address");
        
        (bool success, ) = payable(campaign_info[_campaignId].campaignWinner).call{value: c_Bal}("");
         require(success, "BettingCampaign: Payout to the winner of the campaign failed!");

    }


    function updateEntryFee(uint256 NEW_ENTRY_FEE) external onlyOwner {
        ENTRY_FEE = NEW_ENTRY_FEE;
        emit EntryFeeUpdated(NEW_ENTRY_FEE); 
    }



function setDevAddresses(address payable devAddress_)
    public 
    onlyOwner  
    {
        devAddress = devAddress_;
        emit DevAddressUpdated(devAddress);
    }

}