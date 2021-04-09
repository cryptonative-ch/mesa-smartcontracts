// SPDX-License-Identifier: LGPL-3.0-or-newer
pragma solidity >=0.6.8;
import "../utils/cloneFactory.sol";

interface IParticipantList {
    function init(address[] memory managers) external;
}

contract ParticipantListLauncher is CloneFactory {
    address public participantListTemplate;
    address public factory;

    event ListLaunched(address indexed participantList);

    constructor(address _factory, address _participantListTemplate) public {
        factory = _factory;
        participantListTemplate = _participantListTemplate;
    }

    /// @dev function to launch a participant list
    /// @param managers addresses that can update the participantList
    function launchParticipantManager(address[] memory managers)
        external
        returns (address newList)
    {
        newList = createClone(participantListTemplate);
        emit ListLaunched(newList);

        IParticipantList(newList).init(managers);
    }
}