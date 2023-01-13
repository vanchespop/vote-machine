// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract VoteMachine {

    enum Result { Undefined, Approved, Rejected }
    enum State { Idle, Voting, Ended }

    // vote result
    Result public result;

    // VoteMachine's State
    State private state;

    // vote initiator
    address public owner;

    // vote's main question
    string public proposal;

    // custom voter type
    struct voter {
        string secret;
        bool voted;
        bool exists;
    }

    // voter's mapping
    mapping(address => voter) private voters;

    // voter's address array
    address[] public votersArray; 

    // visible results
    mapping(bytes32 => bool) public results;

    // vote counters
    uint256 private approvalCounter;
    uint256 public voteCounter;

    // declaring custom function modifier for owner-only actions
    modifier onlyOwner() { 
    require(msg.sender == owner);
    _;
    }

    // declaring custom function modifier for voter-only actions
    modifier onlyVoter() {
    require(voters[msg.sender].exists);
    _;
    }

    // declaring custom function modifier for state-specific actions
    modifier onlyState(State _state) { 
    require(state == _state);
    _;
    }

    constructor(string memory voteProposal) {
        // initial setup
        owner = msg.sender;
        proposal = voteProposal;
        state = State.Idle;
        result = Result.Undefined;
        voteCounter = 0;
        approvalCounter = 0;
    }

    function addVoter(address voterAddress, string memory voterSecret) 
        external
        onlyOwner
        onlyState(State.Idle) 
    {
        voter memory newVoter;
        newVoter.secret = voterSecret;
        newVoter.voted = false;
        newVoter.exists = true;
        voters[voterAddress] = newVoter;
        votersArray.push(voterAddress);
    }

    function startVote()
        external
        onlyOwner
        onlyState(State.Idle)
    {
        state = State.Voting;
    }

    function doVote(bool newVote) 
        external 
        onlyVoter
        onlyState(State.Voting)
        returns (string memory success) 
    {
        voter memory _voter = voters[msg.sender];
        if (_voter.voted) { 
            revert();
        } 
        _voter.voted = true;
        results[keccak256(abi.encodePacked(_voter.secret))] = newVote;
        voters[msg.sender] = _voter;
        voteCounter++;
        if ( newVote ) {
            approvalCounter++;
        }
        if ( votersArray.length == voteCounter ) {
             endVote();
        }
        return 'Your Vote Is Registered';
    }

    function endVote() 
        internal
        onlyState(State.Voting) 
    {
        state = State.Ended;
        // counting results
        uint256 approvalVotesCount = voteCounter - (voteCounter / 2);
        if ( approvalCounter >= approvalVotesCount ) {
            result = Result.Approved;
        } else {
            result = Result.Rejected;
        }
    }

    function getKey()
        external
        view
        onlyVoter
        onlyState(State.Ended)
        returns (bytes32 key)
    {
        voter memory _voter = voters[msg.sender];
        return keccak256(abi.encodePacked(_voter.secret));
    }    
}