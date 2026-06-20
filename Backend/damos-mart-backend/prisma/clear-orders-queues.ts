import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  const reviewPhotos = await prisma.reviewPhoto.deleteMany({});
  const reviews = await prisma.review.deleteMany({});
  const queues = await prisma.queue.deleteMany({});
  const orderItems = await prisma.orderItem.deleteMany({});
  const orders = await prisma.order.deleteMany({});
  const notifications = await prisma.notification.deleteMany({
    where: { type: { in: ['QUEUE_READY', 'ORDER_STATUS'] } },
  });

  console.log(
    JSON.stringify(
      {
        reviewPhotos: reviewPhotos.count,
        reviews: reviews.count,
        queues: queues.count,
        orderItems: orderItems.count,
        orders: orders.count,
        notifications: notifications.count,
      },
      null,
      2,
    ),
  );
}

main()
  .catch((error) => {
    console.error(error);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
