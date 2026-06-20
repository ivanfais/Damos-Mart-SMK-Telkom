import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcryptjs';

const prisma = new PrismaClient();

async function main() {
  console.log('🌱 Starting database seeding...');

  // 1. Seed Admin User
  const adminEmail = 'admin@damosmart.com';
  const existingAdmin = await prisma.user.findUnique({
    where: { email: adminEmail },
  });

  if (!existingAdmin) {
    const passwordHash = await bcrypt.hash('admin123', 10);
    await prisma.user.create({
      data: {
        fullName: 'Admin Damos Mart',
        email: adminEmail,
        passwordHash,
        role: 'ADMIN',
        isActive: true,
      },
    });
    console.log('✅ Admin account seeded: admin@damosmart.com / admin123');
  } else {
    console.log('ℹ️ Admin account already exists, skipping.');
  }

  // 2. Seed Categories
  const categoriesData = [
    { name: 'Makanan', sortOrder: 1, iconUrl: '/uploads/categories/makanan.png' },
    { name: 'Minuman', sortOrder: 2, iconUrl: '/uploads/categories/minuman.png' },
    { name: 'Alat Tulis', sortOrder: 3, iconUrl: '/uploads/categories/alat-tulis.png' },
    { name: 'Atribut Sekolah', sortOrder: 4, iconUrl: '/uploads/categories/atribut.png' },
  ];

  const categoriesMap: Record<string, string> = {};

  for (const cat of categoriesData) {
    const existingCat = await prisma.category.findFirst({
      where: { name: cat.name },
    });

    if (!existingCat) {
      const created = await prisma.category.create({
        data: cat,
      });
      categoriesMap[cat.name] = created.id;
      console.log(`✅ Category seeded: ${cat.name}`);
    } else {
      categoriesMap[cat.name] = existingCat.id;
      console.log(`ℹ️ Category already exists: ${cat.name}`);
    }
  }

  // 3. Seed Products
  const productsData = [
    // Makanan
    {
      categoryName: 'Makanan',
      name: 'Roti Coklat',
      description: 'Roti manis isi coklat lumer lezat.',
      price: 5000,
      stock: 50,
      isPreorder: false,
      imageUrl: '/uploads/products/roti-coklat.jpg',
    },
    {
      categoryName: 'Makanan',
      name: 'Nasi Goreng',
      description: 'Nasi goreng spesial dengan telur dadar dan sosis.',
      price: 12000,
      stock: 30,
      isPreorder: false,
      imageUrl: '/uploads/products/nasi-goreng.jpg',
    },
    {
      categoryName: 'Makanan',
      name: 'Mie Goreng',
      description: 'Mie goreng instan dimasak dengan sayuran segar.',
      price: 10000,
      stock: 25,
      isPreorder: false,
      imageUrl: '/uploads/products/mie-goreng.jpg',
    },
    // Minuman
    {
      categoryName: 'Minuman',
      name: 'Es Teh',
      description: 'Es teh manis segar pelepas dahaga.',
      price: 3000,
      stock: 100,
      isPreorder: false,
      imageUrl: '/uploads/products/es-teh.jpg',
    },
    {
      categoryName: 'Minuman',
      name: 'Kopi Susu',
      description: 'Kopi susu dingin dari biji kopi pilihan.',
      price: 8000,
      stock: 40,
      isPreorder: false,
      imageUrl: '/uploads/products/kopi-susu.jpg',
    },
    {
      categoryName: 'Minuman',
      name: 'Air Mineral',
      description: 'Air mineral kemasan botol 600ml.',
      price: 4000,
      stock: 120,
      isPreorder: false,
      imageUrl: '/uploads/products/air-mineral.jpg',
    },
    // Alat Tulis
    {
      categoryName: 'Alat Tulis',
      name: 'Pulpen',
      description: 'Pulpen gel tinta hitam 0.5mm, menulis lebih lancar.',
      price: 3500,
      stock: 150,
      isPreorder: false,
      imageUrl: '/uploads/products/pulpen.jpg',
    },
    {
      categoryName: 'Alat Tulis',
      name: 'Buku Tulis',
      description: 'Buku tulis isi 38 lembar motif sekolah.',
      price: 7000,
      stock: 80,
      isPreorder: false,
      imageUrl: '/uploads/products/buku-tulis.jpg',
    },
    {
      categoryName: 'Alat Tulis',
      name: 'Penghapus',
      description: 'Penghapus karet putih bersih bebas debu.',
      price: 2000,
      stock: 60,
      isPreorder: false,
      imageUrl: '/uploads/products/penghapus.jpg',
    },
    // Atribut Sekolah
    {
      categoryName: 'Atribut Sekolah',
      name: 'Seragam Harian',
      description: 'Seragam sekolah harian SMK Telkom Jakarta berkualitas tinggi.',
      price: 185000,
      stock: 10,
      isPreorder: true,
      preorderEstimation: '7-14 hari',
      imageUrl: '/uploads/products/seragam.jpg',
      variants: [
        { variantName: 'S', additionalPrice: 0, stock: 15 },
        { variantName: 'M', additionalPrice: 0, stock: 20 },
        { variantName: 'L', additionalPrice: 5000, stock: 20 },
        { variantName: 'XL', additionalPrice: 10000, stock: 10 },
      ],
    },
    {
      categoryName: 'Atribut Sekolah',
      name: 'Dasi',
      description: 'Dasi abu-abu bordir logo SMK Telkom Jakarta.',
      price: 25000,
      stock: 45,
      isPreorder: false,
      imageUrl: '/uploads/products/dasi.jpg',
    },
    {
      categoryName: 'Atribut Sekolah',
      name: 'Topi',
      description: 'Topi sekolah SMK Telkom Jakarta dengan perekat di belakang.',
      price: 35000,
      stock: 35,
      isPreorder: false,
      imageUrl: '/uploads/products/topi.jpg',
    },
  ];

  for (const prod of productsData) {
    const categoryId = categoriesMap[prod.categoryName];
    if (!categoryId) continue;

    const existingProduct = await prisma.product.findFirst({
      where: { name: prod.name },
    });

    if (!existingProduct) {
      const created = await prisma.product.create({
        data: {
          categoryId,
          name: prod.name,
          description: prod.description,
          price: prod.price,
          stock: prod.stock,
          isPreorder: prod.isPreorder,
          preorderEstimation: prod.preorderEstimation || null,
          imageUrl: prod.imageUrl,
          isActive: true,
        },
      });

      console.log(`✅ Product seeded: ${prod.name}`);

      // Seed variants if specified
      if (prod.variants) {
        for (const variant of prod.variants) {
          await prisma.productVariant.create({
            data: {
              productId: created.id,
              variantName: variant.variantName,
              additionalPrice: variant.additionalPrice,
              stock: variant.stock,
            },
          });
        }
        console.log(`   └─ Seeded variants for ${prod.name}`);
      }
    } else {
      console.log(`ℹ️ Product already exists: ${prod.name}`);
    }
  }

  // 4. Seed Operating Hours
  // 1=Senin ... 7=Minggu
  const operatingHoursData = [
    { dayOfWeek: 1, openTime: '07:00', closeTime: '16:00', isClosed: false },
    { dayOfWeek: 2, openTime: '07:00', closeTime: '16:00', isClosed: false },
    { dayOfWeek: 3, openTime: '07:00', closeTime: '16:00', isClosed: false },
    { dayOfWeek: 4, openTime: '07:00', closeTime: '16:00', isClosed: false },
    { dayOfWeek: 5, openTime: '07:00', closeTime: '16:00', isClosed: false },
    { dayOfWeek: 6, openTime: '07:00', closeTime: '12:00', isClosed: false },
    { dayOfWeek: 7, openTime: null, closeTime: null, isClosed: true },
  ];

  for (const hour of operatingHoursData) {
    const existingHour = await prisma.operatingHour.findFirst({
      where: { dayOfWeek: hour.dayOfWeek },
    });

    if (!existingHour) {
      await prisma.operatingHour.create({ data: hour });
    }
  }
  console.log('✅ Operating hours seeded.');

  // 5. Seed Cooperative Info
  const infoData = [
    {
      title: 'Tentang Damos Mart',
      content: 'Damos Mart adalah koperasi siswa SMK Telkom Jakarta yang berdiri sebagai wadah pembelajaran kewirausahaan praktis bagi siswa. Kami menyediakan berbagai macam makanan sehat, minuman segar, alat tulis berkualitas, serta atribut resmi sekolah dengan pelayanan digital yang cepat.',
      infoType: 'about',
      imageUrl: '/uploads/cooperative/about.jpg',
      isActive: true,
    },
    {
      title: 'Lokasi Koperasi',
      content: 'Lobby Lantai 1 Gedung A, SMK Telkom Jakarta. Jalan Daan Mogot KM 11, Jakarta Barat.',
      infoType: 'location',
      imageUrl: '/uploads/cooperative/location.jpg',
      isActive: true,
    },
  ];

  for (const info of infoData) {
    const existingInfo = await prisma.cooperativeInfo.findFirst({
      where: { infoType: info.infoType },
    });

    if (!existingInfo) {
      await prisma.cooperativeInfo.create({ data: info });
    }
  }
  console.log('✅ Cooperative info seeded.');

  // 6. Seed Crowd Levels (Hourly averages for weekdays)
  // hourSlot: 0-23, dayOfWeek: 1-7
  // Let's seed slots from 7:00 to 16:00 for Monday-Friday (days 1-5) and Saturday (day 6)
  const crowdSlots = [];
  for (let day = 1; day <= 6; day++) {
    const maxHour = day === 6 ? 12 : 16;
    for (let hour = 7; hour <= maxHour; hour++) {
      let level = 1; // Default low
      if (day <= 5) {
        // Weekday break schedules: Istirahat 1 (09:40-10:15) -> level 5. Istirahat 2 (12:00-13:00) -> level 5.
        if (hour === 9 || hour === 10 || hour === 12) {
          level = 5;
        } else if (hour === 7 || hour === 15 || hour === 16) {
          level = 3; // Medium at start/end of school
        } else {
          level = 2;
        }
      } else {
        // Saturday break times
        if (hour === 9 || hour === 10) {
          level = 4;
        } else {
          level = 2;
        }
      }
      crowdSlots.push({
        hourSlot: hour,
        dayOfWeek: day,
        avgCrowdLevel: level,
      });
    }
  }

  for (const slot of crowdSlots) {
    await prisma.crowdData.upsert({
      where: {
        hourSlot_dayOfWeek: {
          hourSlot: slot.hourSlot,
          dayOfWeek: slot.dayOfWeek,
        },
      },
      update: { avgCrowdLevel: slot.avgCrowdLevel },
      create: slot,
    });
  }
  console.log('✅ Hourly crowd data seeded.');

  await prisma.cooperativeStatus.upsert({
    where: { id: 'default' },
    update: {},
    create: { id: 'default', condition: 'NORMAL' },
  });
  console.log('✅ Cooperative current status seeded.');

  // 7. Seed Demo Student + Sample Complaints
  const studentEmail = 'siswa@damosmart.com';
  let student = await prisma.user.findUnique({ where: { email: studentEmail } });
  if (!student) {
    const studentHash = await bcrypt.hash('siswa123', 10);
    student = await prisma.user.create({
      data: {
        fullName: 'Budi Siswa',
        email: studentEmail,
        phone: '081234567890',
        passwordHash: studentHash,
        role: 'STUDENT',
        isActive: true,
      },
    });
    console.log('✅ Demo student seeded: siswa@damosmart.com / siswa123');
  }

  const complaintsCount = await prisma.complaint.count();
  if (complaintsCount === 0) {
    await prisma.complaint.createMany({
      data: [
        {
          userId: student.id,
          subject: 'Roti coklat sudah kadaluarsa',
          description:
            'Saya membeli roti coklat tadi pagi, tetapi setelah dibuka ternyata sudah berjamur. Mohon diperhatikan tanggal kedaluwarsanya.',
          category: 'PRODUCT',
          status: 'OPEN',
          priority: 'HIGH',
        },
        {
          userId: student.id,
          subject: 'Antrean terlalu lama saat istirahat',
          description:
            'Pada jam istirahat pertama, antrean pengambilan pesanan sangat lama hingga lebih dari 20 menit. Mohon tambah petugas.',
          category: 'QUEUE',
          status: 'IN_PROGRESS',
          priority: 'MEDIUM',
          adminResponse: 'Terima kasih atas masukannya, kami akan menambah petugas pada jam sibuk.',
          respondedAt: new Date(),
        },
        {
          userId: student.id,
          subject: 'Pelayanan petugas kurang ramah',
          description:
            'Mohon petugas koperasi lebih ramah saat melayani pembeli, terutama saat sedang ramai.',
          category: 'SERVICE',
          status: 'RESOLVED',
          priority: 'LOW',
          adminResponse: 'Sudah kami sampaikan ke petugas terkait. Terima kasih.',
          respondedAt: new Date(),
          resolvedAt: new Date(),
        },
      ],
    });
    console.log('✅ Sample complaints seeded.');
  } else {
    console.log('ℹ️ Complaints already exist, skipping sample seed.');
  }

  console.log('🌱 Seeding process complete!');
}

main()
  .catch((e) => {
    console.error('❌ Error during seeding:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
