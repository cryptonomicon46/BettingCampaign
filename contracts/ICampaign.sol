//SPDX-License-Identifier:MIT
pragma solidity =0.7.6;
pragma abicoder v2;
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
     * event Withdraw emitted when either the winner or the dev withdraw their balances
     */
    event Withdraw(address account,uint256  amount);

    /**
     * event CampaignStageChanged emitted when the campaign stage is changed by the owner of the contract
     */
    event CampaignStageChanged(uint256 _campaignId, Stages _stage);
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
        uint256 winnerPayout;
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

    /**
     * @notice WithdrawWinnings uses the Checks/Effects/Interactions pattern with 
     * Reentrancy guard to allow the bet winner to withdraw the campaign funds
     *  @param _campaignId is the campaignID created for a certain race of MotoGP/Moto2 or WSBK.
     */
        function WithdrawWinnings(uint256 _campaignId) external payable;


    /**
     * @notice DevWithdraw allows only the developer to withdraw their 5% fees on all closed campains where the winner's revealed
     * emits the Withdraw event
     */

    function DevWithdraw() external payable;

    /**
     * @notice setDevAddresses allows the owner of the contract to set the developer address.
     * Devs earn 5% of the campaign proceeds
     * emits the DevAddressUpdated event 
     */
    function setDevAddresses(address payable devAddress_) external;

    /**
     * @notice updateEntryFee only owner can update the entry fee for the campaigns
     * @param NEW_ENTRY_FEE is the new entry fee
     * @dev emits the EntryFeeUpdated event 
     */
    function updateEntryFee(uint256 NEW_ENTRY_FEE) external;


}