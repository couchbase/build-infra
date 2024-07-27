This contains the Dockerfile for couchbasebuild/zz-lightweight. It is in
the process of being converted to use Rye for python scripting, and
hence it is somewhat incompatible with older zz-lightweight images. For
the time of the transition, I've done two things:

1. Added a new `zzz-lightweight` service in the corresponding Docker
   stackfile, so that both old and new agents are on server.jenkins.
2. Copied the original Dockerfile to Dockerfile.historic here, in case
   we have a need for an urgent update to the original zz-lightweight
   agent.
