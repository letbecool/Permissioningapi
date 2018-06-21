pragma solidity 0.4.22;

contract Permissions{
    /*
    *Node contains details of nodes and its enode address
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

    //issuspention for suspention phase is running
    bool public issuspention;

     //isadding for adding phase is running 
    bool public isadding;
    
    //addingmutex prevent form  running multiple adding request 
    //if addingmutex == false then we can start new job 
    bool public addingmutex;

    //suspentionmutex prevent form  running multiple suspention request 
    //if suspentionmutex == false then we can start new job 
    bool public suspentionmutex;

    //LimitOfVote is total number of vote need to approve the node
    uint public LimitOfVote;
    
    //previous holds the previous node information
    //it tracks that is the previous information matches the current transaction 
    //this helps to not doing multiple adding and suspend work before successfull completion of job
    bytes32 public previousenode;
    address public previousaccount;
    
    //NodeCount is total number of approved node in the network
    uint public NodeCount;

   //nodeconformations conforms the node to elisible to connect to the network
    mapping(
        bytes32 => bool
            )public nodeconformations;
    
    mapping(
        bytes32 => mapping(
            address => Node
            )
        )public nodeinfo;
     
    event LogOfAddNode(bytes32,address);
    event LogOfSuspentionNode(bytes32,address);    
    
    function Permissions()
        public{
            LimitOfVote = 0;
            NodeCount = 0;
        }
 
    //addNode function enters the enode and account of the proposed node.
    //the node will be eligible to peer with other node when it meets the consensus
    //untill reach to consensus node will be proposed node. If meets the consensus then 
    //it will be approved node. it will be signified by the nodeconformations[enode_of_proposed_node]
    function addNode(bytes32 _enode, address _account)
        public{
            
            if((addingmutex == true) && (previousenode == _enode) && (previousaccount == _account)){
                _addNode(_enode,_account);
            }
            else if((addingmutex == false) && (isadding == false)){
                addingmutex = true;
                _addNode(_enode,_account);
            }
    }
            
    //suspendNode will disable the nodeconformations flag (nodeconformations = false)
    //while checking in the phase of handshake it will check the nodeconformations status
    function suspendNode(bytes32 _enode, address _account)
        public{
             if((suspentionmutex == true) && (previousenode == _enode) && (previousaccount == _account)){
                _suspendNode(_enode,_account);
            }
            else if((suspentionmutex == false) && (issuspention == false)){
                suspentionmutex = true;
                _suspendNode(_enode,_account);
            }
    }
        
    //checkNode checks the seeking node is eligible to peer with existing network 
    //it will be called by api1--> api2
    function checkNode(bytes32 _enode)
        public 
        view 
        returns(bool){
            if(nodeconformations[_enode] == true)
                return true;
            else return false;
    }

    function _addNode(bytes32 _enode, address _account)
        private {
        
            isadding = true;
            
            assert(!nodeconformations[_enode]);
            
            assert(!issuspention);
            
            assert(addingmutex);
            
            if(nodeinfo[_enode][_account].votecount < LimitOfVote){
            nodeinfo[_enode][_account].enode = _enode;
            nodeinfo[_enode][_account].account = _account;
            nodeinfo[_enode][_account].flag = true;
            nodeinfo[_enode][_account].votecount += 1; 
            }
            if(nodeinfo[_enode][_account].votecount == LimitOfVote){
                nodeinfo[_enode][_account].enode = _enode;
                nodeinfo[_enode][_account].account = _account;
                nodeinfo[_enode][_account].flag = true;
                
                addingmutex = false;
                
                //now the adding phase is completed
                isadding = false;

                //nodeconformations is used for check the node from permissions layers in core chain
                nodeconformations[_enode] = true;

                //NodeCount counts the number of node that are verified by the network.
                //this will be incremented only if the consensus is reached
                NodeCount++;

                //now the node is accepted and hence count is set to 0. 
                //if vote count is 0 then we will easily do the process of suspend node 
                nodeinfo[_enode][_account].votecount = 0; 
                LimitOfVote = NodeCount;
            }
            previousenode = _enode;
            previousaccount = _account;
         emit LogOfAddNode(_enode,_account);
     
    }

    function _suspendNode(bytes32 _enode, address _account)
        private{
            //checks if adding is running 
            assert(!isadding);
            
            //checks suspention is running
            assert(suspentionmutex);
            
            //if suspention is running then make suspention flag to true
            issuspention = true;
           
           //still flag is enabled and cannot be set to false.
           //only nodeconformations can decide it  is removed or not.
           assert(nodeinfo[_enode][_account].flag == true);
           
           //checks if node is currently on workable state
           assert(nodeconformations[_enode] == true);

            assert(nodeinfo[_enode][_account].votecount < LimitOfVote);
            nodeinfo[_enode][_account].enode = _enode;
            nodeinfo[_enode][_account].account = _account;
            nodeinfo[_enode][_account].flag = true;
            nodeinfo[_enode][_account].votecount += 1; 
        
            //waiting for final vote and if final vote is equal to limit of vote then changes the states of node count and LimitOfVote and related flags
            if(nodeinfo[_enode][_account].votecount == LimitOfVote){
            
                //set nodeconformations to false and it inticates this node is disabled.
                nodeconformations[_enode] = false;
                issuspention = false;  
                suspentionmutex = false;
                //votecount is set to zero so we can further proceed for addition again if suspended
                nodeinfo[_enode][_account].votecount = 0; 
                NodeCount--;
                LimitOfVote = NodeCount;
            }
        previousenode = _enode;
        previousaccount = _account;
        emit LogOfSuspentionNode(_enode,_account);
    }
}
