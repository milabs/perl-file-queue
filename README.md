perl-file-queue
===============

  Simple file queue written in perl. Use as follows:

    0) clean the queue folder

      FS_QUEUE_STORAGE=/tmp/queue perl queue.pl clean

    1) enqueue

      FS_QUEUE_STORAGE=/tmp/queue perl queue.pl enqueue <file>

    2) dequeue

      FS_QUEUE_STORAGE=/tmp/queue perl queue.pl dequeue <file>

    3) inspect queue size

      FS_QUEUE_STORAGE=/tmp/queue perl queue.pl size

  Use FS_QUEUE_MAXIMUM to specify size limit for the queue.

author, license
===============

Written by Ilya V. Matveychikov, distibuted under GPL v2.
