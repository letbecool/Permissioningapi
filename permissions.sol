pragma solidity 0.4.22;

contract Permissions{
    /*
    Node contains details of nodes and its enode address
    */
    struct Node{
        //enode is e-node address of the node 
        bytes32     enode;
        //account is account associated with node
        address     account;
        //flag represent the node is started to vote or completed
        //flag also represent that this node is already exist in the network
        //flag do not identify this node is currently in peer.
        bool        flag;
        //votecount counts total number of vote for each node
        uint        votecount;
    }
    
    //LimitOfVote is total number of vote need to approve the node
    uint public LimitOfVote;
    
    //NodeCount is total number of approved node in the network
    uint public NodeCount;
    
    //nodeconformations conforms the node to elisible to connect to the network
    mapping(
        bytes32 => bool
            )nodeconformations;
    
    mapping(
        bytes32 => mapping(
            address => Node
            )
        )nodeinfo;
    //addNode function enters the enode and account of the proposed node.
    //the node will be eligible to peer with other node when it meets the consensus
    //untill reach to consensus node will be proposed node. If meets the consensus then 
    //it will be approved node. it will be signified by the nodeconformations[enode_of_proposed_node]
    function addNode(bytes32 _enode, address _account)
        public{
            //if voting is completed upto the Limit of vote then no further voting is needed
            assert(nodeinfo[_enode][_account].votecount <= LimitOfVote);
            nodeinfo[_enode][_account].enode = _enode;
            nodeinfo[_enode][_account].account = _account;
            nodeinfo[_enode][_account].flag = true;
            nodeinfo[_enode][_account].votecount += 1; 
            if(nodeinfo[_enode][_account].votecount == LimitOfVote){
                nodeinfo[_enode][_account].flag = true;
                //nodeconformations is used for check the node from permissions layers in core chain
                nodeconformations[_enode] = true;
                //NodeCount counts the number of node that are verified by the network.
                //this will be incremented only if the consensus is reached
                NodeCount++;
                limit();
            
            }
    }
        
    //delNode actually do not delete the node info. It will disable the nodeconformations flag (nodeconformations = false)
    //while checking in the phase of handshake it will check the nodeconformations status
    function delNode(bytes32 _enode, address _account)
        public{
           //still flag is enabled and cannot be set to false.
           //only nodeconformations can decide it  is removed or not.
           assert(nodeinfo[_enode][_account].flag == true);
           
           assert(nodeconformations[_enode] == true);
           //set nodeconformations to false and it inticates this node is disabled.
           nodeconformations[_enode] = false;
           //if we remove one node then we have to decrease one node from the total count of the node
           //ToDo:- more on removal
           NodeCount--;
           limit();
        }
        
    //checkNode checks the seeking node is elisible to peer with existing network 
    //it will be called by api1--> api2
    function checkNode(bytes32 _enode)
        public 
        view 
        returns(bool){
            if(nodeconformations[_enode] == true)
                return true;
            else return false;
        }

    //function limit is used to update the limit of consensus if changed.    
    function limit () 
        private{
        LimitOfVote = NodeCount;
    }
    
}

