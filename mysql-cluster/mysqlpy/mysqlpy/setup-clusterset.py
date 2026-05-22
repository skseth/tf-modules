# Save as setup_clusterset.py
# Run with: mysqlsh --file setup_clusterset.py

import sys

def setup_local_testing():
    try:
        # --- 2. Create the Primary Cluster ---
        print("\nConnecting to seed instance 3310...")
        shell.connect('root:password123@localhost:3306')
        
        print("Creating primary cluster 'devCluster'...")
        cluster1 = dba.create_cluster('devCluster')
        
        for port in [3320, 3330]:
            print(f"Adding instance {port} to primary cluster...")
            cluster1.add_instance(f'root:password123@localhost:{port}', {'recoveryMethod': 'clone'})

        # --- 3. Initialize the ClusterSet ---
        print("\nInitializing ClusterSet 'myClusterSet'...")
        my_clusterset = cluster1.create_cluster_set('myClusterSet')

        # --- 4. Create and Join Replica Cluster ---
        print("Creating replica cluster 'replicaCluster' via 4410...")
        # Note: create_replica_cluster returns the new cluster object
        cluster2 = my_clusterset.create_replica_cluster('root:password123@localhost:4410', 'replicaCluster')

        for port in [4420, 4430]:
            print(f"Adding instance {port} to replica cluster...")
            cluster2.add_instance(f'root:password123@localhost:{port}', {'recoveryMethod': 'clone'})

        print("\n" + "="*30)
        print("SUCCESS: ClusterSet setup complete.")
        print("="*30)
        print(my_clusterset.status({'extended': 1}))

    except Exception as err:
        print(f"\nFATAL ERROR during setup: {err}")
        sys.exit(1)

# Execute the function
setup_local_testing()
