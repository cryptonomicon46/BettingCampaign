//SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "hardhat/console.sol";
import "./ICampaign.sol";

contract BettingCampaign is Context, Ownable, ReentrancyGuard, ICampaign {
    using SafeMath for uint256;
    uint256 private _totalCampaigns=1;
    uint256 public ENTRY_FEE = 0.5 ether;
    uint256 private _platformFees = 5;   //5%
    address payable public devAddress; //payable?
    uint256 public devFees;
    Bidder[] private bidder;

    /**
     * Campain info to CampaignDetails struct {raceNum,raceDate,stage,league,raceWinner,campaignBal,campaignWinner,winnerPayout}
     */
    mapping(uint256 => CampaignDetails) public campaign_info; 

    /**
     * Mapping to check if an account has already bet in a certain campaign (true/false)
     */
    mapping(uint256 =>mapping(address=>bool))public hasBet;

    /**
     * Mapping to capture the Bidder info per campaign per racerNumber to a struck {userBetVal, userBetTimeStamp, userRacerPick, userAddress}
     */

    mapping(uint256 => mapping(uint256 => Bidder[]))public bidders; //Per racer Number


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
    campaign_info[_totalCampaigns]= CampaignDetails(raceNum,raceDate,Stages.AcceptingBets, league,0,0,address(0),0);
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

        campaign_info[_campaignId].raceWinner = racerWhoWon;

        campaign_info[_campaignId].stage = Stages.RevealWinner;

        if(_findTheCampaignWinner(_campaignId,racerWhoWon)) {
            campaign_info[_campaignId].stage = Stages.Payout;}
        else {
            campaign_info[_campaignId].stage = Stages.Issue;

        }
        emit RaceWinner(_campaignId,campaign_info[_campaignId].campaignWinner,campaign_info[_campaignId].winnerPayout);
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

            for (uint256 i=1; i< WinnersArray.length; i++) {
 
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

         campaign_info[_campaignId].campaignWinner= _campaignWinner;
        devFees = (campaign_info[_campaignId].campaignBal).mul(_platformFees).div(100);
        campaign_info[_campaignId].winnerPayout = (campaign_info[_campaignId].campaignBal).sub(devFees);
         return true;
    

    }

/**
 * @notice WithdrawWinnings uses the Checks/Effects/Interactions pattern with 
 * Reentrancy guard to allow the bet winner to withdraw the campaign funds
 *  @param _campaignId is the campaignID created for a certain race of MotoGP/Moto2 or WSBK.
 */
    function WithdrawWinnings(uint256 _campaignId) external payable virtual override nonReentrant {
      require(campaign_info[_campaignId].stage == Stages.Payout,
        "BettingCampaign: Campaign isn't yet in the payout stage!");
        require(campaign_info[_campaignId].campaignWinner!= address(0),"BettingContract: Invalid payout address");
        require(_msgSender()== campaign_info[_campaignId].campaignWinner,"BettingContract: You didn't win this campaign!");
        
        uint256 c_WinnerBal = campaign_info[_campaignId].winnerPayout;
        address c_WinnerAddr = campaign_info[_campaignId].campaignWinner;
        campaign_info[_campaignId].winnerPayout = 0;
        campaign_info[_campaignId].campaignBal = 0;
        

        (bool success, ) = payable(c_WinnerAddr).call{value: c_WinnerBal}("");
         require(success, "BettingCampaign: Payout to the winner of the campaign failed!");
        emit Withdraw(c_WinnerAddr,c_WinnerBal);
    }

    /**
     * @notice DevWithdraw allows only the developer to withdraw their 5% fees on all closed campains where the winner's revealed
     * emits the Withdraw event
     */

    function DevWithdraw() external virtual override payable nonReentrant { 
    require( devAddress != address(0),"Betting Campaign: Owner hasn't set the developer address!");
    require(_msgSender() == devAddress,"Betting Campaign: You're not the developer of this contract!");

        uint256 _d_Fees = devFees;
        devFees =0;
        (bool success, ) = payable(devAddress).call{value: _d_Fees}("");
         require(success, "BettingCampaign: Payout to the winner of the campaign failed!");

         emit Withdraw(devAddress,_d_Fees);

}


    /**
     * @notice updateEntryFee only owner can update the entry fee for the campaigns
     * @param  NEW_ENTRY_FEE is the new entry fee
     * @dev emits the EntryFeeUpdated event 
     */
    function updateEntryFee(uint256 NEW_ENTRY_FEE) external virtual override onlyOwner {
            ENTRY_FEE = NEW_ENTRY_FEE;
            emit EntryFeeUpdated(NEW_ENTRY_FEE); 
        }


    /**
     * @notice setDevAddresses allows the owner of the contract to set the developer address.
     * Devs earn 5% of the campaign proceeds
     * emits the DevAddressUpdated event 
     */
    function setDevAddresses(address payable devAddress_)
    external virtual override  
    onlyOwner  
    {
        devAddress = devAddress_;
        emit DevAddressUpdated(devAddress);
    }

}