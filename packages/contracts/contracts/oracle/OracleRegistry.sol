/*

  Copyright 2018 bZeroX, LLC
  Inspired by TokenRegistry.sol, Copyright 2017 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity 0.5.3;

import "../openzeppelin-solidity/Ownable.sol";


/// @title Oracle Registry - Oracles added to the bZx network by decentralized governance
contract OracleRegistry is Ownable {

    event LogAddOracle(
        address indexed oracle,
        string name
    );

    event LogRemoveOracle(
        address indexed oracle,
        string name
    );

    event LogOracleNameChange(address indexed oracle, string oldName, string newName);

    mapping (address => OracleMetadata) public oracles;
    mapping (string => address) internal oracleByName;

    address[] public oracleAddresses;

    struct OracleMetadata {
        address oracle;
        string name;
    }

    modifier oracleExists(address _oracle) {
        require(oracles[_oracle].oracle != address(0), "OracleRegistry::oracle doesn't exist");
        _;
    }

    modifier oracleDoesNotExist(address _oracle) {
        require(oracles[_oracle].oracle == address(0), "OracleRegistry::oracle exists");
        _;
    }

    modifier nameDoesNotExist(string memory _name) {
        require(oracleByName[_name] == address(0), "OracleRegistry::name exists");
        _;
    }

    modifier addressNotNull(address _address) {
        require(_address != address(0), "OracleRegistry::address is null");
        _;
    }

    /// @dev Allows owner to add a new oracle to the registry.
    /// @param _oracle Address of new oracle.
    /// @param _name Name of new oracle.
    function addOracle(
        address _oracle,
        string memory _name)
        public
        onlyOwner
        oracleDoesNotExist(_oracle)
        addressNotNull(_oracle)
        nameDoesNotExist(_name)
    {
        oracles[_oracle] = OracleMetadata({
            oracle: _oracle,
            name: _name
        });
        oracleAddresses.push(_oracle);
        oracleByName[_name] = _oracle;
        emit LogAddOracle(
            _oracle,
            _name
        );
    }

    /// @dev Allows owner to remove an existing oracle from the registry.
    /// @param _oracle Address of existing oracle.
    function removeOracle(address _oracle, uint256 _index)
        public
        onlyOwner
        oracleExists(_oracle)
    {
        require(oracleAddresses[_index] == _oracle, "OracleRegistry::invalid index");

        oracleAddresses[_index] = oracleAddresses[oracleAddresses.length - 1];
        oracleAddresses.length -= 1;

        OracleMetadata storage oracle = oracles[_oracle];
        emit LogRemoveOracle(
            oracle.oracle,
            oracle.name
        );
        delete oracleByName[oracle.name];
        delete oracles[_oracle];
    }

    /// @dev Allows owner to modify an existing oracle's name.
    /// @param _oracle Address of existing oracle.
    /// @param _name New name.
    function setOracleName(address _oracle, string memory _name)
        public
        onlyOwner
        oracleExists(_oracle)
        nameDoesNotExist(_name)
    {
        OracleMetadata storage oracle = oracles[_oracle];
        emit LogOracleNameChange(_oracle, oracle.name, _name);
        delete oracleByName[oracle.name];
        oracleByName[_name] = _oracle;
        oracle.name = _name;
    }

    /// @dev Checks if an oracle exists in the registry
    /// @param _oracle Address of registered oracle.
    /// @return True if exists, False otherwise.
    function hasOracle(address _oracle)
        public
        view
        returns (bool) {
        return (oracles[_oracle].oracle == _oracle);
    }

    /// @dev Provides a registered oracle's address when given the oracle name.
    /// @param _name Name of registered oracle.
    /// @return Oracle's address.
    function getOracleAddressByName(string memory _name)
        public
        view
        returns (address) {
        return oracleByName[_name];
    }

    /// @dev Provides a registered oracle's metadata, looked up by address.
    /// @param _oracle Address of registered oracle.
    /// @return Oracle metadata.
    function getOracleMetaData(address _oracle)
        public
        view
        returns (
            address,  //oracleAddress
            string memory   //name
        )
    {
        OracleMetadata memory oracle = oracles[_oracle];
        return (
            oracle.oracle,
            oracle.name
        );
    }

    /// @dev Provides a registered oracle's metadata, looked up by name.
    /// @param _name Name of registered oracle.
    /// @return Oracle metadata.
    function getOracleByName(string memory _name)
        public
        view
        returns (
            address,  //oracleAddress
            string memory    //name
        )
    {
        address _oracle = oracleByName[_name];
        return getOracleMetaData(_oracle);
    }

    /// @dev Returns an array containing all oracle addresses.
    /// @return Array of oracle addresses.
    function getOracleAddresses()
        public
        view
        returns (address[] memory)
    {
        return oracleAddresses;
    }

    /// @dev Returns an array of oracle addresses, an array with the length of each oracle name, and a concatenated string of oracle names
    /// @return Array of oracle names, array of name lengths, concatenated string of all names
    function getOracleList()
        public
        view
        returns (address[] memory, uint256[] memory, string memory)
    {
        address[] memory addresses = oracleAddresses;
        uint256[] memory nameLengths = new uint256[](oracleAddresses.length);
        string memory allStrings;

        if (oracleAddresses.length == 0)
            return (addresses,nameLengths,allStrings);
        
        for (uint256 i = 0; i < oracleAddresses.length; i++) {
            string memory tmp = oracles[oracleAddresses[i]].name;
            nameLengths[i] = bytes(tmp).length;
            allStrings = strConcat(allStrings, tmp);
        }

        return (addresses, nameLengths, allStrings);
    }

    /// @dev Concatenates two strings
    /// @return concatenated string
    function strConcat(
        string  memory _a,
        string  memory _b)
        internal
        pure
        returns (string memory)
    {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        string memory ab = new string(_ba.length + _bb.length);
        bytes memory bab = bytes(ab);
        uint256 k = 0;
        uint256 i;
        for (i = 0; i < _ba.length; i++)
            bab[k++] = _ba[i];
        for (i = 0; i < _bb.length; i++)
            bab[k++] = _bb[i];
        
        return string(bab);
    }
}
