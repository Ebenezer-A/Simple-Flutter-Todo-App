import express from "express";
import mongoose from "mongoose";
import cookieParser from "cookie-parser";
import bcrypt from "bcryptjs";
import cors from "cors";
import helmet from "helmet";

const app = express();

app.use(cors());
app.use(helmet());

app.use(express.json());
app.use(cookieParser());

// MongoDB setup
mongoose
  .connect("mongodb://localhost:27017/flutter_todo", {
    useNewUrlParser: true,
    useUnifiedTopology: true,
  })
  .then(() => console.log("Connected to MongoDB"))
  .catch((err) => console.error("Could not connect to MongoDB", err));

// User model
const User = mongoose.model(
  "User",
  new mongoose.Schema({
    username: { type: String, required: true },
    password: { type: String, required: true },
    email: { type: String, required: true, unique: true },
  })
);

// Task model
const Task = mongoose.model(
  "Task",
  new mongoose.Schema({
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },
    taskName: { type: String, required: true },
    description: { type: String },
  })
);

// Routes
app.post("/signup", async (req, res) => {
  const { username, password, email } = req.body;
  if (!username || !password || !email) {
    return res.status(400).json({ message: "Missing required fields." });
  }

  try {
    const existingUser = await User.findOne({ email: email });
    if (existingUser) {
      return res.status(400).json({ message: "Email already exists." });
    }

    const newUser = new User({
      username: username,
      password: bcrypt.hashSync(password),
      email: email,
    });
    await newUser.save();

    res.status(201).json({ message: "User created successfully." });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Internal server error." });
  }
});

app.post("/login", async (req, res) => {
  const { email, password } = req.body;

  try {
    const user = await User.findOne({ email: email });
    if (!user) {
      return res.status(400).json({ message: "Invalid email or password." });
    }

    const isPasswordValid = bcrypt.compareSync(password, user.password);
    if (!isPasswordValid) {
      return res.status(400).json({ message: "Invalid email or password." });
    }

    // Login successful, return user information
    res.status(200).json({ message: "Login successful.", userId: user._id });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Internal server error." });
  }
});

app.post("/logout", (req, res) => {
  req.logout();
  res.status(200).json({ message: "Logout successful." });
});

// Task routes
app.get("/tasks/:id", async (req, res) => {
  const { id } = req.params;

  const tasks = await Task.find({ userId: id });
  res.json({ items: tasks });
});

app.post("/tasks", async (req, res) => {
  const { taskName, description, userId } = req.body;
  const task = new Task({ userId, taskName, description });
  await task.save();
  res.status(201).json(task);
});

app.put("/tasks/:userId/:taskId", async (req, res) => {
  const { userId, taskId } = req.params;
  const { taskName, description } = req.body;
  const task = await Task.findOneAndUpdate(
    { _id: taskId, userId: userId },
    { taskName, description },
    { new: true }
  );
  if (!task) {
    return res.status(404).json({ message: "Task not found." });
  }
  res.json(task);
});

app.delete("/tasks/:userId/:taskId", async (req, res) => {
  const { userId, taskId } = req.params;
  const task = await Task.findOneAndDelete({ _id: taskId, userId: userId });
  if (!task) {
    return res.status(404).json({ message: "Task not found." });
  }
  res.json(task);
});

// Start the server
const PORT = 5000;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
